import 'dart:convert';
import 'dart:io';

import '../models/event_api_exception.dart';
import '../models/event_announcement.dart';
import '../models/event_summary.dart';
import '../models/create_event_request.dart';
import '../models/confirmed_attendee.dart';

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

  Future<List<EventSummary>> fetchEvents({int? viewerUserId}) async {
    final eventsUri = _baseUri
        .resolve('/eventos')
        .replace(
          queryParameters: viewerUserId == null
              ? null
              : {'id_usuario': viewerUserId.toString()},
        );
    final request = await _httpClient.getUrl(eventsUri);
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

  Future<List<EventSummary>> fetchUserUpcomingEvents(int userId) async {
    final eventsUri = _baseUri.resolve('/usuarios/$userId/eventos');
    final request = await _httpClient.getUrl(eventsUri);
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudieron cargar los próximos eventos.',
    );

    final organized =
        (decoded['eventos_organizados'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(EventSummary.fromJson) ??
        [];
    final attending =
        (decoded['eventos_asistencia'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(EventSummary.fromJson) ??
        [];

    final Map<int, EventSummary> eventMap = {};
    for (var event in organized) {
      if (event.id != null) eventMap[event.id!] = event;
    }
    for (var event in attending) {
      if (event.id != null) eventMap[event.id!] = event;
    }

    final upcoming = eventMap.values.toList();
    upcoming.sort((a, b) {
      if (a.start == null || b.start == null) return 0;
      return a.start!.compareTo(b.start!);
    });

    return upcoming;
  }

  Future<List<EventSummary>> fetchAttendanceHistory({
    required int userId,
  }) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId/eventos/historial'),
    );
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo cargar el historial de eventos.',
    );
    final events = decoded['eventos'];
    if (events is! List) {
      throw const EventApiException('La API devolvio un historial inesperado.');
    }

    return events
        .whereType<Map<String, dynamic>>()
        .map(EventSummary.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> confirmAttendance({
    required int eventId,
    required int userId,
  }) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/eventos/$eventId/asistencias'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'id_usuario': userId, 'estado': 'CONFIRMADA'}));

    final response = await request.close();
    return _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo confirmar la asistencia.',
    );
  }

  Future<Map<String, dynamic>> cancelAttendance({
    required int eventId,
    required int userId,
  }) async {
    final request = await _httpClient.deleteUrl(
      _baseUri.resolve('/eventos/$eventId/asistencias/$userId'),
    );

    final response = await request.close();
    return _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo cancelar la asistencia.',
    );
  }

  Future<List<ConfirmedAttendee>> fetchConfirmedAttendees({
    required int eventId,
  }) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/eventos/$eventId/asistencias'),
    );
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudieron cargar los asistentes.',
    );
    final attendees = decoded['asistencias'];
    if (attendees is! List) {
      throw const EventApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }
    return attendees
        .whereType<Map<String, dynamic>>()
        .map(ConfirmedAttendee.fromJson)
        .toList();
  }

  Future<List<EventAnnouncement>> fetchAnnouncements({
    required int eventId,
  }) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/eventos/$eventId/anuncios'),
    );
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudieron cargar los anuncios.',
    );
    final announcements = decoded['anuncios'];
    if (announcements is! List) {
      throw const EventApiException(
        'La API devolvio una lista de anuncios inesperada.',
      );
    }

    return announcements
        .whereType<Map<String, dynamic>>()
        .map(EventAnnouncement.fromJson)
        .toList();
  }

  Future<EventAnnouncement> publishAnnouncement({
    required int eventId,
    required int authorId,
    required String content,
  }) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/eventos/$eventId/anuncios'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'id_autor': authorId, 'contenido': content}));
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo publicar el anuncio.',
    );
    final announcement = decoded['anuncio'];
    if (announcement is! Map<String, dynamic>) {
      throw const EventApiException('La API devolvio un anuncio inesperado.');
    }
    return EventAnnouncement.fromJson(announcement);
  }

  Future<bool> updateAnnouncementNotifications({
    required int eventId,
    required int userId,
    required bool enabled,
  }) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/eventos/$eventId/asistencias/$userId/notificaciones'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'activas': enabled}));
    final response = await request.close();
    final decoded = await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo actualizar la preferencia de avisos.',
    );
    return decoded['notificaciones_activas'] == true;
  }

  Future<void> deleteEvent({required int eventId, required int userId}) async {
    final eventUri = _baseUri
        .resolve('/eventos/$eventId')
        .replace(queryParameters: {'id_usuario': '$userId'});
    final request = await _httpClient.deleteUrl(eventUri);
    final response = await request.close();
    await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo eliminar el evento.',
    );
  }

  Future<void> cancelEvent({
    required int eventId,
    required int organizerId,
  }) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/eventos/$eventId/cancelacion'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'id_organizador': organizerId}));
    final response = await request.close();
    await _decodeJsonMapResponse(
      response,
      fallbackErrorMessage: 'No se pudo cancelar el evento.',
    );
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

  Future<Map<String, dynamic>> _decodeJsonMapResponse(
    HttpClientResponse response, {
    required String fallbackErrorMessage,
  }) async {
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw EventApiException(
        message ?? fallbackErrorMessage,
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
