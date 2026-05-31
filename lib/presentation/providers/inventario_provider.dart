import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/producto.dart';
import '../../data/models/categoria.dart';
import '../../data/models/movimiento_inventario.dart';
import '../../data/services/inventario_service.dart';

final inventarioServiceProvider =
Provider<InventarioService>((ref) => InventarioService());

final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  return ref.read(inventarioServiceProvider).getCategorias();
});

class ProductosNotifier extends StateNotifier<AsyncValue<List<Producto>>> {
  final InventarioService _service;

  ProductosNotifier(this._service) : super(const AsyncValue.loading()) {
    cargar();
  }

  Future<void> cargar({
    String? categoriaId,
    String? estado,
    String? busqueda,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getProductos(
        categoriaId: categoriaId,
        estado: estado,
        busqueda: busqueda,
      );
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final productosProvider =
StateNotifierProvider<ProductosNotifier, AsyncValue<List<Producto>>>((ref) {
  return ProductosNotifier(ref.read(inventarioServiceProvider));
});

class MovimientosNotifier
    extends StateNotifier<AsyncValue<List<MovimientoInventario>>> {
  final InventarioService _service;

  MovimientosNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> cargar({String? productoId}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getMovimientos(productoId: productoId);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final movimientosProvider =
StateNotifierProvider<MovimientosNotifier,
    AsyncValue<List<MovimientoInventario>>>((ref) {
  return MovimientosNotifier(ref.read(inventarioServiceProvider));
});