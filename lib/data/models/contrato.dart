import 'cliente.dart';
import 'usuario.dart';
import 'detalle_contrato.dart';

class Contrato {
  final String id;
  final String clienteId;
  final String usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaFinEstimada;
  final DateTime? fechaFinReal;
  final double montoTotal;
  final double? depositoGarantia;
  final String estado;
  final String? observaciones;
  final Cliente? cliente;
  final Usuario? usuario;
  final List<DetalleContrato>? detalles;

  const Contrato({
    required this.id,
    required this.clienteId,
    required this.usuarioId,
    required this.fechaInicio,
    required this.fechaFinEstimada,
    this.fechaFinReal,
    required this.montoTotal,
    this.depositoGarantia,
    required this.estado,
    this.observaciones,
    this.cliente,
    this.usuario,
    this.detalles,
  });

  bool get proxAVencer {
    final now = DateTime.now();
    final diff = fechaFinEstimada.difference(now).inDays;
    return estado == 'activo' && diff >= 0 && diff <= 7;
  }

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      usuarioId: json['usuario_id'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFinEstimada: DateTime.parse(json['fecha_fin_estimada'] as String),
      fechaFinReal: json['fecha_fin_real'] != null
          ? DateTime.parse(json['fecha_fin_real'] as String)
          : null,
      montoTotal: (json['monto_total'] as num).toDouble(),
      depositoGarantia: json['deposito_garantia'] != null
          ? (json['deposito_garantia'] as num).toDouble()
          : null,
      estado: json['estado'] as String,
      observaciones: json['observaciones'] as String?,
      cliente: json['clientes'] != null
          ? Cliente.fromJson(json['clientes'] as Map<String, dynamic>)
          : null,
      usuario: json['usuarios'] != null
          ? Usuario.fromJson(json['usuarios'] as Map<String, dynamic>)
          : null,
      detalles: json['detalle_contrato'] != null
          ? (json['detalle_contrato'] as List)
          .map((d) => DetalleContrato.fromJson(d as Map<String, dynamic>))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'fecha_inicio': fechaInicio.toIso8601String().split('T').first,
      'fecha_fin_estimada': fechaFinEstimada.toIso8601String().split('T').first,
      'fecha_fin_real': fechaFinReal?.toIso8601String().split('T').first,
      'monto_total': montoTotal,
      'deposito_garantia': depositoGarantia,
      'estado': estado,
      'observaciones': observaciones,
    };
  }
}