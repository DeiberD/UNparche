/// Event model representing an event in the system
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    this.startDate,
    this.durationMinutes,
    this.endDate,
    this.publishedAt,
    this.latitude,
    this.longitude,
    required this.visibility,
    this.chatEnabled = false,
    required this.status,
    required this.organizerId,
    this.organizerName,
    this.groupId,
    this.groupName,
    required this.eventTypeId,
    this.eventTypeName,
    this.eventTypeIcon,
    this.attendanceStatus,
    this.attendanceConfirmedAt,
  });

  final int id;
  final String title;
  final String description;
  final DateTime? startDate;
  final int? durationMinutes;
  final DateTime? endDate;
  final DateTime? publishedAt;
  final double? latitude;
  final double? longitude;
  final String visibility; // PUBLICA, SOLO_GRUPO, SOLO_AMIGOS
  final bool chatEnabled;
  final String status; // PROGRAMADO, CANCELADO, FINALIZADO
  final int organizerId;
  final String? organizerName;
  final int? groupId;
  final String? groupName;
  final int eventTypeId;
  final String? eventTypeName;
  final String? eventTypeIcon;
  final String? attendanceStatus; // CONFIRMADA, CANCELADA
  final DateTime? attendanceConfirmedAt;

  /// Whether the event has a valid location
  bool get hasLocation => latitude != null && longitude != null;

  /// Event type label for display
  String get typeLabel => eventTypeName ?? 'Evento';

  /// Create Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id_evento'] as int,
      title: json['titulo'] as String,
      description: json['descripcion'] as String,
      startDate: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      durationMinutes: json['duracion_minutos'] as int?,
      endDate: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      publishedAt: json['fecha_publicacion'] != null
          ? DateTime.parse(json['fecha_publicacion'] as String)
          : null,
      latitude: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : null,
      longitude: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      visibility: json['visibilidad'] as String,
      chatEnabled: json['chat_habilitado'] == 1 ||
          json['chat_habilitado'] == true,
      status: json['estado'] as String,
      organizerId: json['id_organizador'] as int,
      organizerName: json['organizador_nombre'] as String?,
      groupId: json['id_grupo'] as int?,
      groupName: json['grupo_nombre'] as String?,
      eventTypeId: json['id_tipo_evento'] as int,
      eventTypeName: json['tipo_evento_nombre'] as String?,
      eventTypeIcon: json['tipo_evento_icono'] as String?,
      attendanceStatus: json['estado_asistencia'] as String?,
      attendanceConfirmedAt: json['fecha_confirmacion'] != null
          ? DateTime.parse(json['fecha_confirmacion'] as String)
          : null,
    );
  }

  /// Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_evento': id,
      'titulo': title,
      'descripcion': description,
      if (startDate != null) 'fecha_inicio': startDate!.toIso8601String(),
      if (durationMinutes != null) 'duracion_minutos': durationMinutes,
      if (endDate != null) 'fecha_fin': endDate!.toIso8601String(),
      if (publishedAt != null) 'fecha_publicacion': publishedAt!.toIso8601String(),
      if (latitude != null) 'latitud': latitude,
      if (longitude != null) 'longitud': longitude,
      'visibilidad': visibility,
      'chat_habilitado': chatEnabled ? 1 : 0,
      'estado': status,
      'id_organizador': organizerId,
      if (organizerName != null) 'organizador_nombre': organizerName,
      if (groupId != null) 'id_grupo': groupId,
      if (groupName != null) 'grupo_nombre': groupName,
      'id_tipo_evento': eventTypeId,
      if (eventTypeName != null) 'tipo_evento_nombre': eventTypeName,
      if (eventTypeIcon != null) 'tipo_evento_icono': eventTypeIcon,
      if (attendanceStatus != null) 'estado_asistencia': attendanceStatus,
      if (attendanceConfirmedAt != null)
        'fecha_confirmacion': attendanceConfirmedAt!.toIso8601String(),
    };
  }
}
