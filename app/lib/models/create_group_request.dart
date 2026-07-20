class CreateGroupRequest {
  const CreateGroupRequest({
    required this.name,
    required this.description,
    required this.category,
    required this.adminId,
  });

  final String name;
  final String description;
  final String category;
  final int adminId;

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'descripcion': description,
      'categoria': category,
      'id_administrador': adminId,
    };
  }
}
