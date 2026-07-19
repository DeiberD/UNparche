class EventSummary {
  const EventSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.durationMinutes,
    required this.end,
    required this.latitude,
    required this.longitude,
    required this.visibility,
    required this.organizerId,
    required this.organizerName,
    required this.organizerEmail,
    required this.organizerCareer,
    required this.organizerInfo,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.groupCategory,
    required this.groupIsOfficial,
    required this.groupVerificationStatus,
    required this.eventTypeId,
    required this.eventTypeName,
    required this.status,
    required this.chatEnabled,
    required this.attendanceStatus,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      id: _toInt(json['id_evento']),
      title: json['titulo']?.toString() ?? '',
      description: json['descripcion']?.toString() ?? '',
      start: _toDateTime(json['fecha_inicio']),
      durationMinutes: _toInt(json['duracion_minutos']),
      end: _toDateTime(json['fecha_fin']),
      latitude: _toDouble(json['latitud']),
      longitude: _toDouble(json['longitud']),
      visibility: json['visibilidad']?.toString() ?? 'PUBLICA',
      organizerId: _toInt(json['id_organizador']),
      organizerName: _cleanString(json['organizador_nombre']),
      organizerEmail: _cleanString(json['organizador_correo']),
      organizerCareer: _cleanString(json['organizador_carrera']),
      organizerInfo: _cleanString(json['organizador_informacion']),
      groupId: _toInt(json['id_grupo']),
      groupName: _cleanString(json['grupo_nombre']),
      groupDescription: _cleanString(json['grupo_descripcion']),
      groupCategory: _cleanString(json['grupo_categoria']),
      groupIsOfficial: _toBool(json['grupo_es_oficial']),
      groupVerificationStatus: _cleanString(json['grupo_estado_verificacion']),
      eventTypeId: _toInt(json['id_tipo_evento']),
      eventTypeName: _cleanString(json['tipo_evento_nombre']),
      status: json['estado']?.toString() ?? 'PROGRAMADO',
      chatEnabled: _toBool(json['chat_habilitado']) ?? false,
      attendanceStatus: _cleanString(json['estado_asistencia']),
    );
  }

  final int? id;
  final String title;
  final String description;
  final DateTime? start;
  final int? durationMinutes;
  final DateTime? end;
  final double? latitude;
  final double? longitude;
  final String visibility;
  final int? organizerId;
  final String? organizerName;
  final String? organizerEmail;
  final String? organizerCareer;
  final String? organizerInfo;
  final int? groupId;
  final String? groupName;
  final String? groupDescription;
  final String? groupCategory;
  final bool? groupIsOfficial;
  final String? groupVerificationStatus;
  final int? eventTypeId;
  final String? eventTypeName;
  final String status;
  final bool chatEnabled;
  final String? attendanceStatus;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isPublic => visibility == 'PUBLICA';
  bool get isActive => status == 'PROGRAMADO' || status == 'EN_CURSO';
  bool get hasConfirmedAttendance => attendanceStatus == 'CONFIRMADA';
  bool get belongsToGroup => groupId != null;
  bool get hasCompleteRequiredDetails =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      start != null &&
      durationMinutes != null &&
      durationMinutes! > 0 &&
      hasLocation &&
      organizerId != null &&
      eventTypeId != null;

  String get eventTypeLabel {
    final apiName = eventTypeName;
    if (apiName != null && apiName.trim().isNotEmpty) {
      return _titleCase(apiName);
    }

    return switch (eventTypeId) {
      1 => 'Academico',
      2 => 'Cultural',
      3 => 'Deportivo',
      4 => 'Social',
      5 => 'Otro',
      _ => 'Evento',
    };
  }

  String get organizerLabel {
    final group = groupName;
    if (belongsToGroup && group != null && group.trim().isNotEmpty) {
      return group;
    }

    final organizer = organizerName;
    if (organizer != null && organizer.trim().isNotEmpty) {
      return organizer;
    }

    return 'Organizador no disponible';
  }

  String get locationLabel {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) {
      return 'Ubicacion no disponible';
    }

    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  EventSummary copyWith({String? attendanceStatus}) {
    return EventSummary(
      id: id,
      title: title,
      description: description,
      start: start,
      durationMinutes: durationMinutes,
      end: end,
      latitude: latitude,
      longitude: longitude,
      visibility: visibility,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerEmail: organizerEmail,
      organizerCareer: organizerCareer,
      organizerInfo: organizerInfo,
      groupId: groupId,
      groupName: groupName,
      groupDescription: groupDescription,
      groupCategory: groupCategory,
      groupIsOfficial: groupIsOfficial,
      groupVerificationStatus: groupVerificationStatus,
      eventTypeId: eventTypeId,
      eventTypeName: eventTypeName,
      status: status,
      chatEnabled: chatEnabled,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    );
  }

  bool isVisibleByDefault(DateTime now) {
    final eventStart = start;
    if (eventStart == null) {
      return false;
    }

    final todayStart = DateTime(now.year, now.month, now.day);
    final next7Days = now.add(const Duration(days: 7));

    return isPublic &&
        isActive &&
        !eventStart.isBefore(todayStart) &&
        !eventStart.isAfter(next7Days);
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is double && value % 1 == 0) {
      return value.toInt();
    }

    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    return null;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim()) ??
        DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
  }

  static String? _cleanString(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool? _toBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is double && value % 1 == 0) {
      return value.toInt() == 1;
    }

    return null;
  }

  static String _titleCase(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.isEmpty) {
      return value;
    }

    return lower[0].toUpperCase() + lower.substring(1);
  }
}
