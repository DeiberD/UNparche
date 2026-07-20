import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_api_client.dart';
import '../models/user.dart';

class AuthState {
  final User? currentUser;
  final String? token;
  final bool isLoading;

  bool get isAuthenticated => token != null && currentUser != null;

  AuthState({this.currentUser, this.token, this.isLoading = true});

  AuthState copyWith({
    User? currentUser,
    String? token,
    bool? isLoading,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : currentUser ?? this.currentUser,
      token: clearToken ? null : token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends ValueNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  AuthNotifier.withState(AuthState initialState) : super(initialState);

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _apiClient = AuthApiClient();

  Future<void> _init() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final user = await _apiClient.getCurrentUser(token);
        value = value.copyWith(
          currentUser: user,
          token: token,
          isLoading: false,
        );
      } else {
        value = value.copyWith(isLoading: false);
      }
    } catch (e) {
      await _storage.delete(key: 'jwt_token');
      value = value.copyWith(
        isLoading: false,
        clearUser: true,
        clearToken: true,
      );
    }
  }

  Future<void> login(String correo, String contrasena) async {
    value = value.copyWith(isLoading: true);
    try {
      final result = await _apiClient.login(correo, contrasena);
      final token = result['token'] as String;
      final userData = result['usuario'];

      await _storage.write(key: 'jwt_token', value: token);
      final user = User.fromJson(userData);

      value = value.copyWith(currentUser: user, token: token, isLoading: false);
    } catch (e) {
      value = value.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    value = value.copyWith(isLoading: true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        clientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled
        value = value.copyWith(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      final result = await _apiClient.loginWithGoogle(idToken);
      final token = result['token'] as String;
      final userData = result['usuario'];

      await _storage.write(key: 'jwt_token', value: token);
      final user = User.fromJson(userData);

      value = value.copyWith(currentUser: user, token: token, isLoading: false);
    } catch (e) {
      value = value.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String contrasena,
    String nickname, {
    String? carrera,
  }) async {
    value = value.copyWith(isLoading: true);
    try {
      final result = await _apiClient.register(
        nombre,
        apellido,
        correo,
        contrasena,
        nickname,
        carrera: carrera,
      );

      if (result['requiereVerificacion'] == true) {
        value = value.copyWith(isLoading: false);
        return true;
      }

      // Legacy fallback just in case
      final token = result['token'] as String;
      final userData = result['usuario'];

      await _storage.write(key: 'jwt_token', value: token);
      final user = User.fromJson(userData);

      value = value.copyWith(currentUser: user, token: token, isLoading: false);
      return false;
    } catch (e) {
      value = value.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loginWithToken(String token, Map<String, dynamic> userData) async {
    await _storage.write(key: 'jwt_token', value: token);
    final user = User.fromJson(userData);
    value = value.copyWith(currentUser: user, token: token, isLoading: false);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    value = value.copyWith(clearUser: true, clearToken: true, isLoading: false);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (value.token == null) return;

    value = value.copyWith(isLoading: true);
    try {
      final updatedUser = await _apiClient.updateProfile(value.token!, updates);
      value = value.copyWith(currentUser: updatedUser, isLoading: false);
    } catch (e) {
      value = value.copyWith(isLoading: false);
      rethrow;
    }
  }
}

class AuthProvider extends InheritedNotifier<AuthNotifier> {
  const AuthProvider({
    super.key,
    required AuthNotifier super.notifier,
    required super.child,
  });

  static AuthNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(provider != null, 'No AuthProvider found in context');
    return provider!.notifier!;
  }
}
