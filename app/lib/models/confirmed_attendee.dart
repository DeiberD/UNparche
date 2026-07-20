class ConfirmedAttendee {
  const ConfirmedAttendee({
    required this.id,
    required this.name,
    required this.nickname,
    required this.career,
    required this.personalInfo,
    required this.profilePhoto,
  });

  factory ConfirmedAttendee.fromJson(Map<String, dynamic> json) {
    return ConfirmedAttendee(
      id: _toInt(json['id_usuario']),
      name: _cleanString(json['usuario_nombre']) ?? 'Usuario',
      nickname: _cleanString(json['nickname']),
      career: _cleanString(json['carrera']),
      personalInfo: _cleanString(json['informacion_personal']),
      profilePhoto: _cleanString(json['foto_perfil']),
    );
  }

  final int? id;
  final String name;
  final String? nickname;
  final String? career;
  final String? personalInfo;
  final String? profilePhoto;
}

int? _toInt(Object? value) => value is int ? value : null;

String? _cleanString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
