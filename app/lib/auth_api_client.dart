import 'dart:convert';
import 'dart:io';

class User {
  final int id;
  final String correoInstitucional;
  final String nombre;
  final String apellido;
  final String? carrera;
  final String? informacionPersonal;
  final String? fotoPerfil;
  final String? nickname;

  User({
    required this.id,
    required this.correoInstitucional,
    required this.nombre,
    required this.apellido,
    this.carrera,
    this.informacionPersonal,
    this.fotoPerfil,
    this.nickname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'],
      correoInstitucional: json['correo_institucional'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      carrera: json['carrera'],
      informacionPersonal: json['informacion_personal'],
      fotoPerfil: json['foto_perfil'],
      nickname: json['nickname'],
    );
  }

  String get chatNickname => nickname ?? ' ';
}

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

  Future<Map<String, dynamic>> register(
    String nombre,
    String apellido,
    String correo,
    String contrasena,
  ) async {
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
