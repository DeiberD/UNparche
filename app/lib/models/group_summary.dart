enum GroupTypeFilter { all, official, unofficial }

const groupCategories = [
  'ACADEMICO',
  'CULTURAL',
  'SOCIAL',
  'DEPORTIVO',
  'OTRO',
];

String groupCategoryLabel(String category) {
  return switch (category) {
    'ACADEMICO' => 'Academico',
    'CULTURAL' => 'Cultural',
    'SOCIAL' => 'Social',
    'DEPORTIVO' => 'Deportivo',
    'OTRO' => 'Otro',
    _ => 'Otro',
  };
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isOfficial,
    required this.verificationStatus,
    required this.adminId,
    required this.memberCount,
    required this.isMember,
    required this.isCreator,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      id: _toInt(json['id_grupo']),
      name: json['nombre']?.toString() ?? 'Grupo',
      description: json['descripcion']?.toString() ?? '',
      category: json['categoria']?.toString() ?? 'OTRO',
      isOfficial: _toBool(json['es_oficial']),
      verificationStatus: json['estado_verificacion']?.toString() ?? '',
      adminId: _toInt(json['id_administrador']),
      memberCount: _toInt(json['cantidad_integrantes']) ?? 0,
      isMember: _toBool(json['es_miembro']),
      isCreator: _toBool(json['es_creador']),
    );
  }

  final int? id;
  final String name;
  final String description;
  final String category;
  final bool isOfficial;
  final String verificationStatus;
  final int? adminId;
  final int memberCount;
  final bool isMember;
  final bool isCreator;

  GroupSummary copyWith({bool? isMember, bool? isCreator}) {
    return GroupSummary(
      id: id,
      name: name,
      description: description,
      category: category,
      isOfficial: isOfficial,
      verificationStatus: verificationStatus,
      adminId: adminId,
      memberCount: memberCount,
      isMember: isMember ?? this.isMember,
      isCreator: isCreator ?? this.isCreator,
    );
  }

  String get categoryLabel => groupCategoryLabel(category);

  bool matches({
    required String query,
    required GroupTypeFilter typeFilter,
    required String? categoryFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty ||
        name.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery);
    final matchesType = switch (typeFilter) {
      GroupTypeFilter.all => true,
      GroupTypeFilter.official => isOfficial,
      GroupTypeFilter.unofficial => !isOfficial,
    };
    final matchesCategory =
        categoryFilter == null || category == categoryFilter;

    return matchesQuery && matchesType && matchesCategory;
  }
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is double && value % 1 == 0) {
    return value.toInt();
  }

  return null;
}

bool _toBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value == 1;
  }

  return false;
}
