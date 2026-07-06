/// Event type model
class EventType {
  const EventType({
    required this.id,
    required this.name,
    this.iconSvg,
  });

  final int id;
  final String name;
  final String? iconSvg;

  /// Create EventType from JSON
  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id_tipo_evento'] as int,
      name: json['nombre'] as String,
      iconSvg: json['icono_svg'] as String?,
    );
  }

  /// Convert EventType to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_tipo_evento': id,
      'nombre': name,
      if (iconSvg != null) 'icono_svg': iconSvg,
    };
  }
}
