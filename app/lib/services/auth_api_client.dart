import 'dart:convert';
import 'dart:io';

import '../models/user.dart';

class AuthApiClient {
  AuthApiClient({String? baseUrl, HttpClient? httpClient})
    : _baseUri = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://127.0.0.1:8787',
            ),
      ) {
    _httpClient = httpClient ?? HttpClient();
  }

  final Uri _baseUri;
  late final HttpClient _httpClient;

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/auth/login'));
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({'correo_institucional': correo, 'contrasena': contrasena}),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error al iniciar sesión');
    }
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/auth/google'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'id_token': idToken}));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Error al iniciar sesión con Google');
    }
    return data;
  }

  Future<Map<String, dynamic>> verificarCorreo(
    String correo,
    String codigo,
  ) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/auth/verificar-correo'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'correo_institucional': correo, 'codigo': codigo}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Código inválido');
    }
    return data;
  }

  Future<void> reenviarCodigo(String correo) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/auth/reenviar-codigo'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'correo_institucional': correo}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error al reenviar código');
    }
  }

  Future<void> olvidePassword(String correo) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/auth/olvide-password'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'correo_institucional': correo}));
    final response = await request.close();
    if (response.statusCode != 200) {
      // Consume body but always succeed (backend returns ok:true regardless)
      await response.drain();
    }
  }

  Future<void> restablecerPassword(
    String correo,
    String codigo,
    String nuevaContrasena,
  ) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/auth/restablecer-password'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'correo_institucional': correo,
      'codigo': codigo,
      'nueva_contrasena': nuevaContrasena,
    }));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Código inválido o expirado');
    }
  }

  Future<Map<String, dynamic>> register(
    String nombre,
    String apellido,
    String correo,
    String contrasena,
    String nickname, {
    String? carrera,
  }) async {
    final request = await _httpClient.postUrl(
      _baseUri.resolve('/auth/register'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'correo_institucional': correo,
        'contrasena': contrasena,
        'nickname': nickname,
        if (carrera != null && carrera.isNotEmpty) 'carrera': carrera,
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Error al registrar usuario');
    }
    return data;
  }

  Future<User> getCurrentUser(String token) async {
    final request = await _httpClient.getUrl(_baseUri.resolve('/usuarios/me'));
    request.headers.add(HttpHeaders.authorizationHeader, 'Bearer $token');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error al obtener usuario');
    }
    return User.fromJson(data['usuario']);
  }

  Future<User> updateProfile(String token, Map<String, dynamic> updates) async {
    final request = await _httpClient.patchUrl(
      _baseUri.resolve('/usuarios/me'),
    );
    request.headers.contentType = ContentType.json;
    request.headers.add(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode(updates));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error al actualizar perfil');
    }
    return User.fromJson(data['usuario']);
  }
}
