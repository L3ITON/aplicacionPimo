import 'empleado.dart';

class Asistencia {
  final String id;
  final String empleadoId;
  final DateTime fecha;
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final String tipoRegistro;
  final String estado;
  final String? observacion;
  final Empleado? empleado;

  const Asistencia({
    required this.id,
    required this.empleadoId,
    required this.fecha,
    this.horaEntrada,
    this.horaSalida,
    required this.tipoRegistro,
    required this.estado,
    this.observacion,
    this.empleado,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'] as String,
      empleadoId: json['empleado_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      horaEntrada: json['hora_entrada'] != null
          ? DateTime.parse(json['hora_entrada'] as String).toLocal()
          : null,
      horaSalida: json['hora_salida'] != null
          ? DateTime.parse(json['hora_salida'] as String).toLocal()
          : null,
      tipoRegistro: json['tipo_registro'] as String? ?? 'manual',
      estado: json['estado'] as String? ?? 'puntual',
      observacion: json['observacion'] as String?,
      empleado: json['empleados'] != null
          ? Empleado.fromJson(json['empleados'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleado_id': empleadoId,
      'fecha': fecha.toIso8601String().split('T').first,
      'hora_entrada': horaEntrada?.toUtc().toIso8601String(),
      'hora_salida': horaSalida?.toUtc().toIso8601String(),
      'tipo_registro': tipoRegistro,
      'estado': estado,
      'observacion': observacion,
    };
  }

  Color get estadoColor {
    switch (estado) {
      case 'puntual':
        return const Color(0xFF2E7D32);
      case 'tardanza':
        return const Color(0xFFF59E0B);
      case 'falta':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ignore: avoid_classes_with_only_static_members
class Color {
  final int value;
  const Color(this.value);
}