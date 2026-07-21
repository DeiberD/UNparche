class User {
  final int id;
  final String correoInstitucional;
  final String nombre;
  final String apellido;
  final String? carrera;
  final String? informacionPersonal;
  final String? fotoPerfil;
  final String? nickname;
  final String? rol;
  final String? fechaCreacion;

  User({
    required this.id,
    required this.correoInstitucional,
    required this.nombre,
    required this.apellido,
    this.carrera,
    this.informacionPersonal,
    this.fotoPerfil,
    this.nickname,
    this.rol,
    this.fechaCreacion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'] as int,
      correoInstitucional: json['correo_institucional'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      carrera: json['carrera'] as String?,
      informacionPersonal: json['informacion_personal'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      nickname: json['nickname'] as String?,
      rol: json['rol'] as String?,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }

  String get nombreCompleto => '$nombre $apellido';

  String get chatNickname {
    final value = nickname?.trim();

    if (value == null || value.isEmpty) {
      return nombreCompleto;
    }

    return value;
  }
}