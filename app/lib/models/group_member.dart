class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['id_usuario'] is int ? json['id_usuario'] as int : null,
      name: json['usuario_nombre']?.toString() ?? 'Usuario',
      email: json['correo_institucional']?.toString() ?? '',
      role: json['rol_grupo']?.toString() ?? 'MIEMBRO',
    );
  }

  final int? userId;
  final String name;
  final String email;
  final String role;

  bool get isAdministrator => role == 'ADMINISTRADOR';
}
