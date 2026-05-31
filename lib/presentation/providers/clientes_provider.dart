import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cliente.dart';
import '../../data/services/cliente_service.dart';

final clienteServiceProvider =
Provider<ClienteService>((ref) => ClienteService());

class ClientesNotifier extends StateNotifier<AsyncValue<List<Cliente>>> {
  final ClienteService _service;

  ClientesNotifier(this._service) : super(const AsyncValue.loading()) {
    cargar();
  }

  Future<void> cargar({String? busqueda}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getClientes(busqueda: busqueda);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final clientesProvider =
StateNotifierProvider<ClientesNotifier, AsyncValue<List<Cliente>>>((ref) {
  return ClientesNotifier(ref.read(clienteServiceProvider));
});