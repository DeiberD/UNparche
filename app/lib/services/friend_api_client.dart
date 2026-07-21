import 'dart:convert';
import 'dart:io';

import 'event_api_client.dart';
import '../models/user.dart';
import '../models/friend_request.dart';
import '../models/friend_api_exception.dart';

class FriendApiClient {
  FriendApiClient({String? baseUrl, HttpClient? httpClient})
    : _baseUri = Uri.parse(baseUrl ?? EventApiClient.defaultBaseUrl),
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  // GET /usuarios/{id}
  Future<Map<String, dynamic>> fetchUserProfile({
    required int userId,
    required String token,
  }) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId'),
    );

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudo cargar el perfil del usuario.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['usuario'] is! Map<String, dynamic>) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }

    return {
      'usuario': User.fromJson(decoded['usuario'] as Map<String, dynamic>),
      'estadoAmistad': decoded['estado_amistad'] as String,
    };
  }

  // GET /usuarios?buscar={texto}
  Future<List<User>> searchUsers({
    required String query,
    required String token,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final uri = _baseUri
        .resolve('/usuarios')
        .replace(queryParameters: {'buscar': normalizedQuery});

    final request = await _httpClient.getUrl(uri);

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudieron buscar usuarios.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['usuarios'] is! List) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }

    return (decoded['usuarios'] as List)
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  // GET /usuarios/{id}/amigos
  Future<List<User>> fetchFriends({required int userId}) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId/amigos'),
    );

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudieron cargar los amigos.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['amigos'] is! List) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }

    return (decoded['amigos'] as List)
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  // GET /usuarios/{id}/solicitudes-amistad
  Future<List<FriendRequest>> fetchPendingRequests({
    required int userId,
  }) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId/solicitudes-amistad'),
    );

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudieron cargar las solicitudes de amistad.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['solicitudes'] is! List) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }

    return (decoded['solicitudes'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FriendRequest.fromJson)
        .toList();
  }

  // POST /amistades
  Future<void> sendFriendRequest({
    required int requesterId,
    required int receiverId,
  }) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/amistades'));

    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({'id_solicitante': requesterId, 'id_receptor': receiverId}),
    );

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudo enviar la solicitud de amistad.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }
  }

  // PATCH /amistades/{id}
  Future<void> respondFriendRequest({
    required int friendshipId,
    required bool accept,
  }) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/amistades/$friendshipId'),
    );

    request.headers.contentType = ContentType.json;

    request.write(jsonEncode({'estado': accept ? 'ACEPTADA' : 'RECHAZADA'}));

    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw FriendApiException(
        message ?? 'No se pudo responder la solicitud de amistad.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw const FriendApiException(
        'La API devolvió una respuesta inesperada.',
      );
    }
  }

  // DELETE /amistades/{id} (via PATCH estado=ELIMINADA)
  Future<void> removeFriend({required int friendshipId}) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/amistades/$friendshipId'),
    );

    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'estado': 'ELIMINADA'}));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw FriendApiException(
        message ?? 'No se pudo eliminar al amigo.',
        statusCode: response.statusCode,
      );
    }
  }
}
