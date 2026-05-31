class Devolucion {
  final String id;
  final String contratoId;
  final String empleadoId;
  final DateTime fechaDevolucion;
  final String estadoProducto;
  final double? cargoExtra;
  final String? observacion;

  const Devolucion({
    required this.id,
    required this.contratoId,
    required this.empleadoId,
    required this.fechaDevolucion,
    required this.estadoProducto,
    this.cargoExtra,
    this.observacion,
  });

  factory Devolucion.fromJson(Map<String, dynamic> json) {
    return Devolucion(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String,
      empleadoId: json['empleado_id'] as String,
      fechaDevolucion: DateTime.parse(json['fecha_devolucion'] as String).toLocal(),
      estadoProducto: json['estado_producto'] as String,
      cargoExtra: json['cargo_extra'] != null
          ? (json['cargo_extra'] as num).toDouble()
          : null,
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contrato_id': contratoId,
      'empleado_id': empleadoId,
      'fecha_devolucion': fechaDevolucion.toUtc().toIso8601String(),
      'estado_producto': estadoProducto,
      'cargo_extra': cargoExtra,
      'observacion': observacion,
    };
  }
}