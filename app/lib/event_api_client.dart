import 'dart:convert';
import 'dart:io';

class EventApiClient {
  EventApiClient({String? baseUrl, HttpClient? httpClient})
    : _baseUri = Uri.parse(baseUrl ?? defaultBaseUrl),
      _httpClient = httpClient ?? HttpClient();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return Platform.isAndroid
        ? 'http://10.0.2.2:8787'
        : 'http://127.0.0.1:8787';
  }

  final Uri _baseUri;
  final HttpClient _httpClient;

  Future<List<EventSummary>> fetchEvents() async {
    final request = await _httpClient.getUrl(_baseUri.resolve('/eventos'));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw EventApiException(
        message ?? 'No se pudieron cargar los eventos.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['eventos'] is! List) {
      throw const EventApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    return (decoded['eventos'] as List)
        .whereType<Map<String, dynamic>>()
        .map(EventSummary.fromJson)
        .where((event) => event.hasLocation)
        .toList();
  }

  Future<Map<String, dynamic>> createEvent(CreateEventRequest event) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/eventos'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(event.toJson()));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw EventApiException(
        message ?? 'No se pudo crear el evento.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const EventApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    return decoded;
  }
}

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

  bool get hasLocation => latitude != null && longitude != null;
  bool get isPublic => visibility == 'PUBLICA';
  bool get isActive => status == 'PROGRAMADO' || status == 'EN_CURSO';
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

class EventApiException implements Exception {
  const EventApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
