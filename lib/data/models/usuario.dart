class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String rol;
  final String estado;
  final DateTime? createdAt;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    required this.rol,
    required this.estado,
    this.createdAt,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String,
      estado: json['estado'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'estado': estado,
    };
  }
}