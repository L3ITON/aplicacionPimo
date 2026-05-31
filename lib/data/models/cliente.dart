class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String? dniRuc;
  final String? telefono;
  final String? email;
  final String? direccion;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.dniRuc,
    this.telefono,
    this.email,
    this.direccion,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      dniRuc: json['dni_ruc'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'dni_ruc': dniRuc,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
    };
  }
}
 