import 'package:aplicacionpimo/data/models/Devolucion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/contrato.dart';


class ContratoService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Contrato>> getContratos({
    String? estado,
    String? busqueda,
  }) async {
    var query = _client
        .from('contratos')
        .select('*, clientes(*), usuarios(*), detalle_contrato(*, productos(*))');

    if (estado != null) {
      query = query.eq('estado', estado);
    }

    final data = await query.order('fecha_inicio', ascending: false);
    List<Contrato> contratos =
    (data as List).map((e) => Contrato.fromJson(e)).toList();

    if (busqueda != null && busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      contratos = contratos
          .where((c) =>
      c.cliente?.nombreCompleto.toLowerCase().contains(q) ?? false)
          .toList();
    }

    return contratos;
  }

  Future<Contrato?> getContratoPorId(String id) async {
    try {
      final data = await _client
          .from('contratos')
          .select('*, clientes(*), usuarios(*), detalle_contrato(*, productos(*))')
          .eq('id', id)
          .single();
      return Contrato.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Contrato>> getContratosProxAVencer() async {
    final now = DateTime.now();
    final en7Dias = now.add(const Duration(days: 7));
    final data = await _client
        .from('contratos')
        .select('*, clientes(*), usuarios(*)')
        .eq('estado', 'activo')
        .gte('fecha_fin_estimada', now.toIso8601String().split('T').first)
        .lte('fecha_fin_estimada', en7Dias.toIso8601String().split('T').first)
        .order('fecha_fin_estimada');
    return (data as List).map((e) => Contrato.fromJson(e)).toList();
  }

  Future<Contrato> crearContrato({
    required String clienteId,
    required String usuarioId,
    required DateTime fechaInicio,
    required DateTime fechaFinEstimada,
    required double montoTotal,
    double? depositoGarantia,
    String? observaciones,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final contratoId = _uuid.v4();

    // Insertar contrato
    await _client.from('contratos').insert({
      'id': contratoId,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'fecha_inicio': fechaInicio.toIso8601String().split('T').first,
      'fecha_fin_estimada': fechaFinEstimada.toIso8601String().split('T').first,
      'monto_total': montoTotal,
      'deposito_garantia': depositoGarantia,
      'estado': 'activo',
      'observaciones': observaciones,
    });

    // Insertar detalles y actualizar stock
    for (final detalle in detalles) {
      await _client.from('detalle_contrato').insert({
        'id': _uuid.v4(),
        'contrato_id': contratoId,
        ...detalle,
      });

      // Reducir stock disponible
      final prodData = await _client
          .from('productos')
          .select('stock_disponible')
          .eq('id', detalle['producto_id'])
          .single();
      final stockActual = (prodData['stock_disponible'] as num).toInt();
      final nuevoStock = stockActual - (detalle['cantidad'] as int);

      await _client.from('productos').update({
        'stock_disponible': nuevoStock,
        'estado': nuevoStock <= 0 ? 'agotado' : 'disponible',
      }).eq('id', detalle['producto_id']);
    }

    final contrato = await getContratoPorId(contratoId);
    return contrato!;
  }

  Future<void> cerrarContrato(String contratoId) async {
    await _client.from('contratos').update({
      'estado': 'cerrado',
      'fecha_fin_real': DateTime.now().toIso8601String().split('T').first,
    }).eq('id', contratoId);
  }

  Future<Devolucion> registrarDevolucion({
    required String contratoId,
    required String empleadoId,
    required String estadoProducto,
    double? cargoExtra,
    String? observacion,
    required List<Map<String, dynamic>> productosDevueltos,
  }) async {
    final devId = _uuid.v4();

    await _client.from('devoluciones').insert({
      'id': devId,
      'contrato_id': contratoId,
      'empleado_id': empleadoId,
      'fecha_devolucion': DateTime.now().toUtc().toIso8601String(),
      'estado_producto': estadoProducto,
      'cargo_extra': cargoExtra,
      'observacion': observacion,
    });

    // Restaurar stock por producto devuelto
    for (final p in productosDevueltos) {
      final prodData = await _client
          .from('productos')
          .select('stock_disponible, stock_total')
          .eq('id', p['producto_id'])
          .single();

      final stockActual = (prodData['stock_disponible'] as num).toInt();
      final stockTotal = (prodData['stock_total'] as num).toInt();
      final cantidad = (p['cantidad'] as int);
      final nuevoStock = (stockActual + cantidad).clamp(0, stockTotal);

      await _client.from('productos').update({
        'stock_disponible': nuevoStock,
        'estado': nuevoStock > 0 ? 'disponible' : 'agotado',
      }).eq('id', p['producto_id']);
    }

    final data = await _client
        .from('devoluciones')
        .select()
        .eq('id', devId)
        .single();
    return Devolucion.fromJson(data);
  }

  Future<List<Contrato>> getContratosVencidos() async {
    final hoy = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('contratos')
        .select('*, clientes(*), usuarios(*)')
        .eq('estado', 'activo')
        .lt('fecha_fin_estimada', hoy)
        .order('fecha_fin_estimada');
    return (data as List).map((e) => Contrato.fromJson(e)).toList();
  }
}