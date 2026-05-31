import 'categoria.dart';

class Producto {
  final String id;
  final String? categoriaId;
  final String codigoQr;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final int stockTotal;
  final int stockDisponible;
  final double? precioAlquilerDia;
  final double? precioVenta;
  final String estado;
  final String? imagenUrl;
  final Categoria? categoria;

  const Producto({
    required this.id,
    this.categoriaId,
    required this.codigoQr,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    required this.stockTotal,
    required this.stockDisponible,
    this.precioAlquilerDia,
    this.precioVenta,
    required this.estado,
    this.imagenUrl,
    this.categoria,
  });

  double get porcentajeStock =>
      stockTotal > 0 ? stockDisponible / stockTotal : 0;

  bool get stockBajo => porcentajeStock < 0.2 && stockTotal > 0;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      categoriaId: json['categoria_id'] as String?,
      codigoQr: json['codigo_qr'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      tipo: json['tipo'] as String,
      stockTotal: (json['stock_total'] as num).toInt(),
      stockDisponible: (json['stock_disponible'] as num).toInt(),
      precioAlquilerDia: json['precio_alquiler_dia'] != null
          ? (json['precio_alquiler_dia'] as num).toDouble()
          : null,
      precioVenta: json['precio_venta'] != null
          ? (json['precio_venta'] as num).toDouble()
          : null,
      estado: json['estado'] as String,
      imagenUrl: json['imagen_url'] as String?,
      categoria: json['categorias'] != null
          ? Categoria.fromJson(json['categorias'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'codigo_qr': codigoQr,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'stock_total': stockTotal,
      'stock_disponible': stockDisponible,
      'precio_alquiler_dia': precioAlquilerDia,
      'precio_venta': precioVenta,
      'estado': estado,
      'imagen_url': imagenUrl,
    };
  }
}