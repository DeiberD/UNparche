import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../models/group.dart';
import '../models/event_type.dart';
import '../models/group_invitation.dart';

/// API client for UNparche backend
class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl = baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8787');

  final String _baseUrl;

  /// Get headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['error'] as String? ?? 'Error desconocido',
        statusCode: response.statusCode,
      );
    }
  }

  // ==================== AUTH ENDPOINTS ====================
  // Note: Auth endpoints will need to be implemented in the backend

  /// Login with email and password
  /// TODO: Implement in backend
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      // Placeholder - backend endpoint needs to be implemented
      throw UnimplementedError('Login endpoint not yet implemented in backend');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al iniciar sesión: $e');
    }
  }

  /// Register new user
  /// TODO: Implement in backend
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String career,
  }) async {
    try {
      // Placeholder - backend endpoint needs to be implemented
      throw UnimplementedError('Register endpoint not yet implemented in backend');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al registrar usuario: $e');
    }
  }

  /// Request password reset
  /// TODO: Implement in backend
  Future<void> resetPassword({required String email}) async {
    try {
      // Placeholder - backend endpoint needs to be implemented
      throw UnimplementedError('Password reset endpoint not yet implemented in backend');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al solicitar recuperación: $e');
    }
  }

  // ==================== USER ENDPOINTS ====================

  /// Get user by ID
  Future<User> getUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/$userId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return User.fromJson(data['usuario'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener usuario: $e');
    }
  }

  /// Get user's events (organized and attending)
  Future<Map<String, List<Event>>> getUserEvents(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/$userId/eventos'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      
      final organized = (data['eventos_organizados'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
      
      final attending = (data['eventos_asistencia'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'organized': organized,
        'attending': attending,
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener eventos del usuario: $e');
    }
  }

  /// Get user's group invitations
  Future<List<GroupInvitation>> getUserGroupInvitations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/$userId/invitaciones-grupo'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return (data['invitaciones'] as List)
          .map((e) => GroupInvitation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener invitaciones: $e');
    }
  }

  // ==================== EVENT ENDPOINTS ====================

  /// Get all events
  Future<List<Event>> getEvents({int? userId}) async {
    try {
      final uri = userId != null
          ? Uri.parse('$_baseUrl/eventos?id_usuario=$userId')
          : Uri.parse('$_baseUrl/eventos');

      final response = await http.get(uri, headers: _getHeaders());
      final data = _handleResponse(response);
      
      return (data['eventos'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener eventos: $e');
    }
  }

  /// Get event by ID
  Future<Event> getEvent(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/eventos/$eventId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return Event.fromJson(data['evento'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener evento: $e');
    }
  }

  /// Create new event
  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required int durationMinutes,
    required double latitude,
    required double longitude,
    required String visibility,
    required int organizerId,
    required int eventTypeId,
    int? groupId,
    bool chatEnabled = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eventos'),
        headers: _getHeaders(),
        body: json.encode({
          'titulo': title,
          'descripcion': description,
          'fecha_inicio': startDate.toIso8601String(),
          'duracion_minutos': durationMinutes,
          'latitud': latitude,
          'longitud': longitude,
          'visibilidad': visibility,
          'id_organizador': organizerId,
          'id_tipo_evento': eventTypeId,
          if (groupId != null) 'id_grupo': groupId,
          'chat_habilitado': chatEnabled,
        }),
      );

      final data = _handleResponse(response);
      return Event.fromJson(data['evento'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al crear evento: $e');
    }
  }

  // ==================== GROUP ENDPOINTS ====================

  /// Get all groups
  Future<List<Group>> getGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/grupos'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return (data['grupos'] as List)
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener grupos: $e');
    }
  }

  /// Get group by ID
  Future<Group> getGroup(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/grupos/$groupId'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return Group.fromJson(data['grupo'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener grupo: $e');
    }
  }

  // ==================== EVENT TYPE ENDPOINTS ====================

  /// Get all event types
  Future<List<EventType>> getEventTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tipos-evento'),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);
      return (data['tipos_evento'] as List)
          .map((e) => EventType.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al obtener tipos de evento: $e');
    }
  }

  // ==================== ATTENDANCE ENDPOINTS ====================

  /// Confirm attendance to an event
  Future<void> confirmAttendance({
    required int eventId,
    required int userId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/eventos/$eventId/asistencias'),
        headers: _getHeaders(),
        body: json.encode({
          'id_usuario': userId,
          'estado': 'CONFIRMADA',
        }),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al confirmar asistencia: $e');
    }
  }

  /// Cancel attendance to an event
  Future<void> cancelAttendance({
    required int eventId,
    required int userId,
  }) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/eventos/$eventId/asistencias/$userId'),
        headers: _getHeaders(),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error al cancelar asistencia: $e');
    }
  }
}

/// API Exception
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
