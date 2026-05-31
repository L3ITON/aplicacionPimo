import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/contrato.dart';
import '../../data/services/contrato_service.dart';

final contratoServiceProvider =
Provider<ContratoService>((ref) => ContratoService());

class ContratosNotifier extends StateNotifier<AsyncValue<List<Contrato>>> {
  final ContratoService _service;

  ContratosNotifier(this._service) : super(const AsyncValue.loading()) {
    cargar();
  }

  Future<void> cargar({String? estado, String? busqueda}) async {
    state = const AsyncValue.loading();
    try {
      final result =
      await _service.getContratos(estado: estado, busqueda: busqueda);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final contratosProvider =
StateNotifierProvider<ContratosNotifier, AsyncValue<List<Contrato>>>((ref) {
  return ContratosNotifier(ref.read(contratoServiceProvider));
});

final contratosProxVencerProvider =
FutureProvider<List<Contrato>>((ref) async {
  return ref.read(contratoServiceProvider).getContratosProxAVencer();
});