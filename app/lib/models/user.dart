class User {
  final int id;
  final String correoInstitucional;
  final String nombre;
  final String apellido;
  final String? carrera;
  final String? informacionPersonal;
  final String? fotoPerfil;
  final String? nickname;

  User({
    required this.id,
    required this.correoInstitucional,
    required this.nombre,
    required this.apellido,
    this.carrera,
    this.informacionPersonal,
    this.fotoPerfil,
    this.nickname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'],
      correoInstitucional: json['correo_institucional'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      carrera: json['carrera'],
      informacionPersonal: json['informacion_personal'],
      fotoPerfil: json['foto_perfil'],
      nickname: json['nickname'],
    );
  }

  String get chatNickname => nickname ?? ' ';
}
