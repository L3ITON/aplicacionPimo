import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/asistencia.dart';
import '../models/empleado.dart';

class AsistenciaService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Asistencia>> getAsistenciasHoy() async {
    final hoy = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('asistencias')
        .select('*, empleados(*, usuarios(*))')
        .eq('fecha', hoy)
        .order('hora_entrada', ascending: false);

    return (data as List).map((e) => Asistencia.fromJson(e)).toList();
  }

  Future<List<Asistencia>> getHistorial({
    String? empleadoId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    var query = _client
        .from('asistencias')
        .select('*, empleados(*, usuarios(*))');

    if (empleadoId != null) {
      query = query.eq('empleado_id', empleadoId);
    }
    if (desde != null) {
      query = query.gte('fecha', desde.toIso8601String().split('T').first);
    }
    if (hasta != null) {
      query = query.lte('fecha', hasta.toIso8601String().split('T').first);
    }

    final data = await query.order('fecha', ascending: false).limit(200);
    return (data as List).map((e) => Asistencia.fromJson(e)).toList();
  }

  Future<List<Asistencia>> getResumenMensual({
    required String empleadoId,
    required int year,
    required int month,
  }) async {
    final inicio = DateTime(year, month, 1).toIso8601String().split('T').first;
    final fin = DateTime(year, month + 1, 0).toIso8601String().split('T').first;

    final data = await _client
        .from('asistencias')
        .select('*, empleados(*, usuarios(*))')
        .eq('empleado_id', empleadoId)
        .gte('fecha', inicio)
        .lte('fecha', fin)
        .order('fecha', ascending: true);

    return (data as List).map((e) => Asistencia.fromJson(e)).toList();
  }

  /// Registra QR: si no tiene entrada hoy → crea registro con hora_entrada.
  /// Si ya tiene entrada → actualiza hora_salida.
  Future<Map<String, dynamic>> registrarPorQr(String empleadoId) async {
    final hoy = DateTime.now().toIso8601String().split('T').first;

    // Buscar si ya existe registro hoy
    final existente = await _client
        .from('asistencias')
        .select()
        .eq('empleado_id', empleadoId)
        .eq('fecha', hoy)
        .maybeSingle();

    final ahora = DateTime.now().toUtc().toIso8601String();

    if (existente == null) {
      // Primera vez: registrar entrada
      final empleadoData = await _client
          .from('empleados')
          .select('hora_entrada_esperada')
          .eq('id', empleadoId)
          .single();

      String estado = 'puntual';
      final esperada = empleadoData['hora_entrada_esperada'] as String?;
      if (esperada != null) {
        final now = DateTime.now();
        final parts = esperada.split(':');
        final horaEsperada = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        if (now.isAfter(horaEsperada.add(const Duration(minutes: 10)))) {
          estado = 'tardanza';
        }
      }

      await _client.from('asistencias').insert({
        'id': _uuid.v4(),
        'empleado_id': empleadoId,
        'fecha': hoy,
        'hora_entrada': ahora,
        'tipo_registro': 'qr',
        'estado': estado,
      });
      return {'accion': 'entrada', 'estado': estado};
    } else if (existente['hora_salida'] == null) {
      // Segunda vez: registrar salida
      await _client
          .from('asistencias')
          .update({'hora_salida': ahora})
          .eq('id', existente['id']);
      return {'accion': 'salida', 'estado': existente['estado']};
    } else {
      return {'accion': 'ya_completo', 'estado': existente['estado']};
    }
  }

  Future<Empleado?> getEmpleadoPorId(String empleadoId) async {
    try {
      final data = await _client
          .from('empleados')
          .select('*, usuarios(*)')
          .eq('id', empleadoId)
          .single();
      return Empleado.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Empleado>> getEmpleados() async {
    final data = await _client
        .from('empleados')
        .select('*, usuarios(*)')
        .order('id');
    return (data as List).map((e) => Empleado.fromJson(e)).toList();
  }

  Future<void> registrarManual({
    required String empleadoId,
    required DateTime fecha,
    required DateTime horaEntrada,
    DateTime? horaSalida,
    required String estado,
    String? observacion,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T').first;
    final existente = await _client
        .from('asistencias')
        .select()
        .eq('empleado_id', empleadoId)
        .eq('fecha', fechaStr)
        .maybeSingle();

    final payload = {
      'empleado_id': empleadoId,
      'fecha': fechaStr,
      'hora_entrada': horaEntrada.toUtc().toIso8601String(),
      'hora_salida': horaSalida?.toUtc().toIso8601String(),
      'tipo_registro': 'manual',
      'estado': estado,
      'observacion': observacion,
    };

    if (existente == null) {
      await _client.from('asistencias').insert({
        'id': _uuid.v4(),
        ...payload,
      });
    } else {
      await _client
          .from('asistencias')
          .update(payload)
          .eq('id', existente['id']);
    }
  }
}
