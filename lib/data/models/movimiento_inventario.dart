import 'producto.dart';
import 'usuario.dart';

class MovimientoInventario {
  final String id;
  final String productoId;
  final String usuarioId;
  final String tipoMovimiento;
  final int cantidad;
  final String? motivo;
  final DateTime fecha;
  final Producto? producto;
  final Usuario? usuario;

  const MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.usuarioId,
    required this.tipoMovimiento,
    required this.cantidad,
    this.motivo,
    required this.fecha,
    this.producto,
    this.usuario,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      id: json['id'] as String,
      productoId: json['producto_id'] as String,
      usuarioId: json['usuario_id'] as String,
      tipoMovimiento: json['tipo_movimiento'] as String,
      cantidad: (json['cantidad'] as num).toInt(),
      motivo: json['motivo'] as String?,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      producto: json['productos'] != null
          ? Producto.fromJson(json['productos'] as Map<String, dynamic>)
          : null,
      usuario: json['usuarios'] != null
          ? Usuario.fromJson(json['usuarios'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'usuario_id': usuarioId,
      'tipo_movimiento': tipoMovimiento,
      'cantidad': cantidad,
      'motivo': motivo,
      'fecha': fecha.toUtc().toIso8601String(),
    };
  }
}