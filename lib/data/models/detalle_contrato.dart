import 'producto.dart';

class DetalleContrato {
  final String id;
  final String contratoId;
  final String productoId;
  final int cantidad;
  final double precioUnitarioDia;
  final double subtotal;
  final Producto? producto;

  const DetalleContrato({
    required this.id,
    required this.contratoId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitarioDia,
    required this.subtotal,
    this.producto,
  });

  factory DetalleContrato.fromJson(Map<String, dynamic> json) {
    return DetalleContrato(
      id: json['id'] as String,
      contratoId: json['contrato_id'] as String,
      productoId: json['producto_id'] as String,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitarioDia: (json['precio_unitario_dia'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      producto: json['productos'] != null
          ? Producto.fromJson(json['productos'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contrato_id': contratoId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario_dia': precioUnitarioDia,
      'subtotal': subtotal,
    };
  }
}