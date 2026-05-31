import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/asistencia.dart';
import '../../data/models/empleado.dart';
import '../../data/services/asistencia_service.dart';

final asistenciaServiceProvider =
Provider<AsistenciaService>((ref) => AsistenciaService());

final asistenciasHoyProvider = FutureProvider<List<Asistencia>>((ref) async {
  return ref.read(asistenciaServiceProvider).getAsistenciasHoy();
});

final empleadosProvider = FutureProvider<List<Empleado>>((ref) async {
  return ref.read(asistenciaServiceProvider).getEmpleados();
});

class AsistenciaHistorialNotifier
    extends StateNotifier<AsyncValue<List<Asistencia>>> {
  final AsistenciaService _service;

  AsistenciaHistorialNotifier(this._service)
      : super(const AsyncValue.data([]));

  Future<void> cargar({
    String? empleadoId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getHistorial(
        empleadoId: empleadoId,
        desde: desde,
        hasta: hasta,
      );
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final asistenciaHistorialProvider =
StateNotifierProvider<AsistenciaHistorialNotifier,
    AsyncValue<List<Asistencia>>>((ref) {
  return AsistenciaHistorialNotifier(ref.read(asistenciaServiceProvider));
});