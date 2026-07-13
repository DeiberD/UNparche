import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'models/user.dart';
import 'services/api_client.dart';

/// Authentication service that manages user session state
///
/// This service handles:
/// - User login and logout
/// - Session persistence
/// - Authentication state changes
class AuthService extends ChangeNotifier {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  User? _currentUser;
  bool _isLoading = false;

  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Current authenticated user, null if not authenticated
  User? get currentUser => _currentUser;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Whether an authentication operation is in progress
  bool get isLoading => _isLoading;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthResult.error(
      'El inicio por correo todavía no está disponible. Usa Google institucional.',
    );
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? (_googleIosClientId.isEmpty ? null : _googleIosClientId)
            : null,
        serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.error('Inicio de sesión cancelado por el usuario.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.error(
          'No se pudo obtener el token de Google. Verifica que la huella SHA-1 del app esté registrada en Google Cloud Console y que el GOOGLE_WEB_CLIENT_ID sea un cliente de tipo "Web Application".',
        );
      }

      // Call API
      final user = await _apiClient.loginWithGoogle(idToken: idToken);
      _currentUser = user;

      _isLoading = false;
      notifyListeners();

      return AuthResult.success();
    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.error(e.message);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.error('Error al iniciar sesión con Google: $e');
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String career,
  }) async {
    return AuthResult.error(
      'El registro por correo todavía no está disponible. Usa Google institucional.',
    );
  }

  /// Request password reset
  Future<AuthResult> resetPassword({required String email}) async {
    return AuthResult.error(
      'La recuperación por correo todavía no está disponible.',
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _currentUser = null;
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out of Google: $e');
    }
    notifyListeners();
  }

  /// Load user session from storage (called on app start)
  Future<void> loadSession() async {
    // TODO: Load from secure storage
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Fetch and update current user data from API
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final user = await _apiClient.getUser(_currentUser!.id);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      // Silently fail - keep existing user data
      debugPrint('Error refreshing user: $e');
    }
  }

  /// Update local user data (used by profile edit screen)
  /// In production this would call the backend PATCH endpoint.
  void updateUser({
    String? name,
    String? lastName,
    String? career,
    String? personalInfo,
  }) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name,
      lastName: lastName,
      career: career,
      personalInfo: personalInfo,
    );
    notifyListeners();
  }
}

/// Result of an authentication operation
class AuthResult {
  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => const AuthResult._(success: true);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, errorMessage: message);

  final bool success;
  final String? errorMessage;
}
