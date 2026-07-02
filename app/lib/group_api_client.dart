import 'dart:convert';
import 'dart:io';

import 'event_api_client.dart';

class GroupApiClient {
  GroupApiClient({String? baseUrl, HttpClient? httpClient})
    : _baseUri = Uri.parse(baseUrl ?? EventApiClient.defaultBaseUrl),
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  Future<List<GroupSummary>> fetchGroups() async {
    final request = await _httpClient.getUrl(_baseUri.resolve('/grupos'));
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

    return GroupSummary.fromJson(decoded['grupo'] as Map<String, dynamic>);
  }

  Future<List<GroupInvitation>> fetchInvitations({required int userId}) async {
    final request = await _httpClient.getUrl(
      _baseUri.resolve('/usuarios/$userId/invitaciones-grupo'),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

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
  }) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/invitaciones-grupo/$invitationId'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'estado': status}));

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
}

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isOfficial,
    required this.verificationStatus,
    required this.adminId,
    required this.memberCount,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      id: _toInt(json['id_grupo']),
      name: json['nombre']?.toString() ?? 'Grupo',
      description: json['descripcion']?.toString() ?? '',
      category: json['categoria']?.toString() ?? 'OTRO',
      isOfficial: _toBool(json['es_oficial']),
      verificationStatus: json['estado_verificacion']?.toString() ?? '',
      adminId: _toInt(json['id_administrador']),
      memberCount: _toInt(json['cantidad_integrantes']) ?? 0,
    );
  }

  final int? id;
  final String name;
  final String description;
  final String category;
  final bool isOfficial;
  final String verificationStatus;
  final int? adminId;
  final int memberCount;

  String get categoryLabel => groupCategoryLabel(category);

  bool matches({
    required String query,
    required GroupTypeFilter typeFilter,
    required String? categoryFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty ||
        name.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery);
    final matchesType = switch (typeFilter) {
      GroupTypeFilter.all => true,
      GroupTypeFilter.official => isOfficial,
      GroupTypeFilter.unofficial => !isOfficial,
    };
    final matchesCategory =
        categoryFilter == null || category == categoryFilter;

    return matchesQuery && matchesType && matchesCategory;
  }
}

class GroupInvitation {
  const GroupInvitation({
    required this.id,
    required this.status,
    required this.group,
    required this.inviterName,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: _toInt(json['id_invitacion_grupo']),
      status: json['estado']?.toString() ?? 'PENDIENTE',
      group: GroupSummary.fromJson(json),
      inviterName: json['nombre_invitador']?.toString() ?? 'Un miembro',
    );
  }

  final int? id;
  final String status;
  final GroupSummary group;
  final String inviterName;

  bool get isPending => status == 'PENDIENTE';
}

class CreateGroupRequest {
  const CreateGroupRequest({
    required this.name,
    required this.description,
    required this.category,
    required this.adminId,
  });

  final String name;
  final String description;
  final String category;
  final int adminId;

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'descripcion': description,
      'categoria': category,
      'id_administrador': adminId,
    };
  }
}

enum GroupTypeFilter { all, official, unofficial }

const groupCategories = [
  'ACADEMICO',
  'CULTURAL',
  'SOCIAL',
  'DEPORTIVO',
  'OTRO',
];

String groupCategoryLabel(String category) {
  return switch (category) {
    'ACADEMICO' => 'Academico',
    'CULTURAL' => 'Cultural',
    'SOCIAL' => 'Social',
    'DEPORTIVO' => 'Deportivo',
    'OTRO' => 'Otro',
    _ => 'Otro',
  };
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is double && value % 1 == 0) {
    return value.toInt();
  }

  return null;
}

bool _toBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value == 1;
  }

  return false;
}

class GroupApiException implements Exception {
  const GroupApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
