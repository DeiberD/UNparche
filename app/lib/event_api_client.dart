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

class EventApiException implements Exception {
  const EventApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
