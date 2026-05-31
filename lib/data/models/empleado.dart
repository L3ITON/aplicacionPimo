import 'usuario.dart';

class Empleado {
  final String id;
  final String usuarioId;
  final String? dni;
  final String? cargo;
  final String? horaEntradaEsperada;
  final String? horaSalidaEsperada;
  final DateTime? fechaIngreso;
  final Usuario? usuario;

  const Empleado({
    required this.id,
    required this.usuarioId,
    this.dni,
    this.cargo,
    this.horaEntradaEsperada,
    this.horaSalidaEsperada,
    this.fechaIngreso,
    this.usuario,
  });

  String get nombreCompleto => usuario?.nombreCompleto ?? 'Empleado';

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      dni: json['dni'] as String?,
      cargo: json['cargo'] as String?,
      horaEntradaEsperada: json['hora_entrada_esperada'] as String?,
      horaSalidaEsperada: json['hora_salida_esperada'] as String?,
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'] as String)
          : null,
      usuario: json['usuarios'] != null
          ? Usuario.fromJson(json['usuarios'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'dni': dni,
      'cargo': cargo,
      'hora_entrada_esperada': horaEntradaEsperada,
      'hora_salida_esperada': horaSalidaEsperada,
      'fecha_ingreso': fechaIngreso?.toIso8601String().split('T').first,
    };
  }
}