/// Group model representing a group in the system
class Group {
  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.isOfficial = false,
    this.verificationStatus = 'PENDIENTE',
    this.createdAt,
    required this.adminId,
    this.adminName,
    this.memberCount = 0,
  });

  final int id;
  final String name;
  final String? description;
  final String category; // ACADEMICO, CULTURAL, SOCIAL, DEPORTIVO, OTRO
  final bool isOfficial;
  final String verificationStatus; // PENDIENTE, VERIFICADO, RECHAZADO
  final DateTime? createdAt;
  final int adminId;
  final String? adminName;
  final int memberCount;

  /// Category label for display
  String get categoryLabel {
    switch (category) {
      case 'ACADEMICO':
        return 'Académico';
      case 'CULTURAL':
        return 'Cultural';
      case 'SOCIAL':
        return 'Social';
      case 'DEPORTIVO':
        return 'Deportivo';
      case 'OTRO':
        return 'Otro';
      default:
        return category;
    }
  }

  /// Create Group from JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id_grupo'] as int,
      name: json['nombre'] as String,
      description: json['descripcion'] as String?,
      category: json['categoria'] as String,
      isOfficial: json['es_oficial'] == 1 || json['es_oficial'] == true,
      verificationStatus: json['estado_verificacion'] as String? ?? 'PENDIENTE',
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
      adminId: json['id_administrador'] as int,
      adminName: json['administrador_nombre'] as String?,
      memberCount: (json['cantidad_integrantes'] as int?) ??
          (json['total_miembros'] as int?) ??
          0,
    );
  }

  /// Convert Group to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_grupo': id,
      'nombre': name,
      'descripcion': description,
      'categoria': category,
      'es_oficial': isOfficial ? 1 : 0,
      'estado_verificacion': verificationStatus,
      if (createdAt != null) 'fecha_creacion': createdAt!.toIso8601String(),
      'id_administrador': adminId,
      if (adminName != null) 'administrador_nombre': adminName,
      'cantidad_integrantes': memberCount,
    };
  }
}
