import 'dart:convert';
import 'dart:io';

import '../models/event_api_exception.dart';
import '../models/event_summary.dart';
import '../models/create_event_request.dart';

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
