import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../models/movimiento_inventario.dart';

class InventarioService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─── Categorías ───────────────────────────────────────────────────────────

  Future<List<Categoria>> getCategorias() async {
    final data = await _client
        .from('categorias')
        .select()
        .order('nombre');
    return (data as List).map((e) => Categoria.fromJson(e)).toList();
  }

  // ─── Productos ────────────────────────────────────────────────────────────

  Future<List<Producto>> getProductos({
    String? categoriaId,
    String? estado,
    String? busqueda,
  }) async {
    var query = _client
        .from('productos')
        .select('*, categorias(*)');

    if (categoriaId != null) {
      query = query.eq('categoria_id', categoriaId);
    }
    if (estado != null) {
      query = query.eq('estado', estado);
    }

    final data = await query.order('nombre');
    List<Producto> productos =
    (data as List).map((e) => Producto.fromJson(e)).toList();

    if (busqueda != null && busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      productos = productos
          .where((p) =>
      p.nombre.toLowerCase().contains(q) ||
          p.codigoQr.toLowerCase().contains(q))
          .toList();
    }

    return productos;
  }

  Future<Producto?> getProductoPorQr(String codigoQr) async {
    try {
      final data = await _client
          .from('productos')
          .select('*, categorias(*)')
          .eq('codigo_qr', codigoQr)
          .single();
      return Producto.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Producto?> getProductoPorId(String id) async {
    try {
      final data = await _client
          .from('productos')
          .select('*, categorias(*)')
          .eq('id', id)
          .single();
      return Producto.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Producto> crearProducto(Map<String, dynamic> payload) async {
    final id = _uuid.v4();
    payload['id'] = id;
    payload['codigo_qr'] = id; // El QR almacena el UUID del producto
    final data = await _client
        .from('productos')
        .insert(payload)
        .select('*, categorias(*)')
        .single();
    return Producto.fromJson(data);
  }

  Future<Producto> actualizarProducto(
      String id, Map<String, dynamic> payload) async {
    final data = await _client
        .from('productos')
        .update(payload)
        .eq('id', id)
        .select('*, categorias(*)')
        .single();
    return Producto.fromJson(data);
  }

  // ─── Movimientos ──────────────────────────────────────────────────────────

  Future<List<MovimientoInventario>> getMovimientos({
    String? productoId,
    int limit = 100,
  }) async {
    var query = _client
        .from('movimientos_inventario')
        .select('*, productos(*), usuarios(*)');

    if (productoId != null) {
      query = query.eq('producto_id', productoId);
    }

    final data = await query
        .order('fecha', ascending: false)
        .limit(limit);
    return (data as List).map((e) => MovimientoInventario.fromJson(e)).toList();
  }

  Future<void> registrarMovimiento({
    required String productoId,
    required String usuarioId,
    required String tipoMovimiento,
    required int cantidad,
    String? motivo,
  }) async {
    // Obtener stock actual
    final prod = await getProductoPorId(productoId);
    if (prod == null) throw Exception('Producto no encontrado');

    int nuevoStock = prod.stockDisponible;
    if (tipoMovimiento == 'entrada') {
      nuevoStock = prod.stockDisponible + cantidad;
    } else if (tipoMovimiento == 'salida') {
      if (prod.stockDisponible < cantidad) {
        throw Exception('Stock insuficiente. Disponible: ${prod.stockDisponible}');
      }
      nuevoStock = prod.stockDisponible - cantidad;
    } else if (tipoMovimiento == 'ajuste') {
      nuevoStock = cantidad;
    }

    final nuevoEstado = nuevoStock <= 0
        ? 'agotado'
        : (nuevoStock < prod.stockTotal * 0.2 ? 'disponible' : 'disponible');

    // Actualizar stock
    await _client.from('productos').update({
      'stock_disponible': nuevoStock,
      'estado': nuevoEstado,
    }).eq('id', productoId);

    // Insertar movimiento
    await _client.from('movimientos_inventario').insert({
      'id': _uuid.v4(),
      'producto_id': productoId,
      'usuario_id': usuarioId,
      'tipo_movimiento': tipoMovimiento,
      'cantidad': cantidad,
      'motivo': motivo,
      'fecha': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Producto>> getProductosStockBajo() async {
    final data = await _client
        .from('productos')
        .select('*, categorias(*)')
        .order('nombre');

    final todos = (data as List).map((e) => Producto.fromJson(e)).toList();
    return todos.where((p) => p.stockBajo).toList();
  }
}