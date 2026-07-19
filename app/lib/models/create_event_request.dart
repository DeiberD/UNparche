class CreateEventRequest {
  const CreateEventRequest({
    required this.title,
    required this.description,
    required this.start,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
    required this.visibility,
    required this.organizerId,
    required this.eventTypeId,
    required this.chatEnabled,
    this.groupId,
  });

  final String title;
  final String description;
  final DateTime start;
  final int durationMinutes;
  final double latitude;
  final double longitude;
  final String visibility;
  final int organizerId;
  final int eventTypeId;
  final int? groupId;
  final bool chatEnabled;

  Map<String, dynamic> toJson() {
    return {
      'titulo': title,
      'descripcion': description,
      'fecha_inicio': start.toUtc().toIso8601String(),
      'duracion_minutos': durationMinutes,
      'latitud': latitude,
      'longitud': longitude,
      'visibilidad': visibility,
      'id_organizador': organizerId,
      'id_tipo_evento': eventTypeId,
      'id_grupo': groupId,
      'chat_habilitado': chatEnabled,
    };
  }
}

class CreateEventRequestBuilder {
  String? _title;
  String? _description;
  DateTime? _start;
  int? _durationMinutes;
  double? _latitude;
  double? _longitude;
  String? _visibility;
  int? _organizerId;
  int? _eventTypeId;
  int? _groupId;
  bool? _chatEnabled;

  CreateEventRequestBuilder withTitle(String value) {
    _title = value;
    return this;
  }

  CreateEventRequestBuilder withDescription(String value) {
    _description = value;
    return this;
  }

  CreateEventRequestBuilder startingAt(DateTime value) {
    _start = value;
    return this;
  }

  CreateEventRequestBuilder lastingMinutes(int value) {
    _durationMinutes = value;
    return this;
  }

  CreateEventRequestBuilder atLocation({
    required double latitude,
    required double longitude,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    return this;
  }

  CreateEventRequestBuilder visibleAs(String value) {
    _visibility = value;
    return this;
  }

  CreateEventRequestBuilder organizedBy(int value) {
    _organizerId = value;
    return this;
  }

  CreateEventRequestBuilder typedAs(int value) {
    _eventTypeId = value;
    return this;
  }

  CreateEventRequestBuilder forGroup(int? value) {
    _groupId = value;
    return this;
  }

  CreateEventRequestBuilder withChatEnabled(bool value) {
    _chatEnabled = value;
    return this;
  }

  CreateEventRequest build() {
    final title = _title;
    final description = _description;
    final start = _start;
    final durationMinutes = _durationMinutes;
    final latitude = _latitude;
    final longitude = _longitude;
    final visibility = _visibility;
    final organizerId = _organizerId;
    final eventTypeId = _eventTypeId;
    final chatEnabled = _chatEnabled;

    if (title == null ||
        description == null ||
        start == null ||
        durationMinutes == null ||
        latitude == null ||
        longitude == null ||
        visibility == null ||
        organizerId == null ||
        eventTypeId == null ||
        chatEnabled == null) {
      throw StateError('Faltan campos para construir la solicitud de evento.');
    }

    return CreateEventRequest(
      title: title,
      description: description,
      start: start,
      durationMinutes: durationMinutes,
      latitude: latitude,
      longitude: longitude,
      visibility: visibility,
      organizerId: organizerId,
      eventTypeId: eventTypeId,
      groupId: _groupId,
      chatEnabled: chatEnabled,
    );
  }
}
