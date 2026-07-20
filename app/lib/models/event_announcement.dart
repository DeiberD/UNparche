class EventAnnouncement {
  const EventAnnouncement({
    required this.id,
    required this.content,
    required this.publishedAt,
    required this.authorId,
    required this.authorName,
    required this.authorNickname,
  });

  factory EventAnnouncement.fromJson(Map<String, dynamic> json) {
    return EventAnnouncement(
      id: _toInt(json['id_anuncio']),
      content: json['contenido']?.toString().trim() ?? '',
      publishedAt: _toDateTime(json['fecha_publicacion']),
      authorId: _toInt(json['id_autor']),
      authorName: _cleanString(json['autor_nombre']),
      authorNickname: _cleanString(json['autor_nickname']),
    );
  }

  final int? id;
  final String content;
  final DateTime? publishedAt;
  final int? authorId;
  final String? authorName;
  final String? authorNickname;

  String get authorLabel => authorName ?? authorNickname ?? 'Organizador';

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num && value % 1 == 0) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDateTime(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  static String? _cleanString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
