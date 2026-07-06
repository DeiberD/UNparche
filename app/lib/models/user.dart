/// User model representing a user in the system
class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.lastName,
    required this.career,
    this.personalInfo,
    this.role = 'ESTUDIANTE',
    this.createdAt,
  });

  final int id;
  final String email;
  final String name;
  final String lastName;
  final String career;
  final String? personalInfo;
  final String role;
  final DateTime? createdAt;

  /// Full name of the user
  String get fullName => '$name $lastName';

  /// Biography or personal information
  String get bio => personalInfo ?? '';

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'] as int,
      email: json['correo_institucional'] as String,
      name: json['nombre'] as String,
      lastName: json['apellido'] as String,
      career: json['carrera'] as String,
      personalInfo: json['informacion_personal'] as String?,
      role: json['rol'] as String? ?? 'ESTUDIANTE',
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_usuario': id,
      'correo_institucional': email,
      'nombre': name,
      'apellido': lastName,
      'carrera': career,
      'informacion_personal': personalInfo,
      'rol': role,
      if (createdAt != null) 'fecha_creacion': createdAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    int? id,
    String? email,
    String? name,
    String? lastName,
    String? career,
    String? personalInfo,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      career: career ?? this.career,
      personalInfo: personalInfo ?? this.personalInfo,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
