import 'dart:convert';
import 'dart:io';

import 'event_api_client.dart';
import '../models/group_summary.dart';
import '../models/group_invitation.dart';
import '../models/create_group_request.dart';
import '../models/group_api_exception.dart';
import '../models/group_member.dart';

class GroupApiClient {
  GroupApiClient({String? baseUrl, HttpClient? httpClient})
    : _baseUri = Uri.parse(baseUrl ?? EventApiClient.defaultBaseUrl),
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  Future<List<GroupSummary>> fetchGroups({int? userId}) async {
    final groupsUri = _baseUri
        .resolve('/grupos')
        .replace(
          queryParameters: userId == null ? null : {'id_usuario': '$userId'},
        );
    final request = await _httpClient.getUrl(groupsUri);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudieron cargar los grupos.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['grupos'] is! List) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    return (decoded['grupos'] as List)
        .whereType<Map<String, dynamic>>()
        .map(GroupSummary.fromJson)
        .toList();
  }

  Future<GroupSummary> createGroup(CreateGroupRequest group) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/grupos'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(group.toJson()));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudo crear el grupo.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['grupo'] is! Map<String, dynamic>) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    // El creador se registra también como miembro activo en la misma operación.
    // La respuesta de algunas versiones desplegadas de la API todavía no incluye
    // estas dos banderas, así que las establecemos con la información de la
    // solicitud para que la interfaz se actualice correctamente de inmediato.
    return GroupSummary.fromJson(
      decoded['grupo'] as Map<String, dynamic>,
    ).copyWith(isMember: true, isCreator: true);
  }

  Future<List<GroupMember>> fetchGroupMembers({required int groupId}) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/grupos/$groupId/miembros'),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudieron cargar los integrantes.',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic> || decoded['miembros'] is! List) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }
    return (decoded['miembros'] as List)
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();
  }

  Future<void> deleteGroup({required int groupId, required int userId}) async {
    final uri = _baseUri
        .resolve('/grupos/$groupId')
        .replace(queryParameters: {'id_usuario': '$userId'});
    final request = await _httpClient.deleteUrl(uri);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudo eliminar el grupo.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<GroupInvitation>> fetchInvitations({required int userId}) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId/invitaciones-grupo'),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode == 404) {
      return const [];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudieron cargar las invitaciones.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['invitaciones'] is! List) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    return (decoded['invitaciones'] as List)
        .whereType<Map<String, dynamic>>()
        .map(GroupInvitation.fromJson)
        .toList();
  }

  Future<GroupInvitation> respondInvitation({
    required int invitationId,
    required String status,
    required int userId,
  }) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/invitaciones-grupo/$invitationId'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'estado': status, 'id_usuario': userId}));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudo responder la invitacion.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['invitacion'] is! Map<String, dynamic>) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }

    return GroupInvitation.fromJson(
      decoded['invitacion'] as Map<String, dynamic>,
    );
  }

  Future<GroupInvitation> inviteToGroup({
    required int groupId,
    required int inviterId,
    required String institutionalEmail,
  }) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/grupos/$groupId/invitaciones'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'id_invitador': inviterId,
        'correo_institucional': institutionalEmail,
      }),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw GroupApiException(
        message ?? 'No se pudo enviar la invitacion.',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['invitacion'] is! Map<String, dynamic>) {
      throw const GroupApiException(
        'La API devolvio una respuesta inesperada.',
      );
    }
    return GroupInvitation.fromJson(
      decoded['invitacion'] as Map<String, dynamic>,
    );
  }
}
