import 'package:flutter/foundation.dart';

import 'models/user.dart';
import 'services/api_client.dart';

/// Authentication service that manages user session state
/// 
/// This service handles:
/// - User login and logout
/// - Session persistence
/// - Authentication state changes
class AuthService extends ChangeNotifier {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  User? _currentUser;
  bool _isLoading = false;

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
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call when backend implements auth
      // final user = await _apiClient.login(email: email, password: password);
      
      // Temporary mock - will be replaced with real API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock user - in production this will come from the API
      _currentUser = const User(
        id: 1,
        email: 'deiber.gongora@unal.edu.co',
        name: 'Deiber',
        lastName: 'Gongora',
        career: 'Ingeniería de Sistemas',
        personalInfo: 'Systems Engineering student 🎓 | French learner 🇫🇷\nAlways looking for optimization problems.',
        role: 'ESTUDIANTE',
      );

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
      return AuthResult.error('Error al iniciar sesión. Intenta de nuevo.');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Google Sign-In
      await Future.delayed(const Duration(seconds: 2));

      // Mock user
      _currentUser = const User(
        id: 1,
        email: 'deiber.gongora@unal.edu.co',
        name: 'Deiber',
        lastName: 'Gongora',
        career: 'Ingeniería de Sistemas',
        personalInfo: 'Systems Engineering student 🎓 | French learner 🇫🇷\nAlways looking for optimization problems.',
        role: 'ESTUDIANTE',
      );

      _isLoading = false;
      notifyListeners();

      return AuthResult.success();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.error('Error al iniciar sesión con Google.');
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
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call when backend implements registration
      // final user = await _apiClient.register(
      //   email: email,
      //   password: password,
      //   name: name,
      //   lastName: lastName,
      //   career: career,
      // );

      // Temporary mock
      await Future.delayed(const Duration(seconds: 2));

      _currentUser = User(
        id: 1,
        email: email,
        name: name,
        lastName: lastName,
        career: career,
        personalInfo: '',
        role: 'ESTUDIANTE',
      );

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
      return AuthResult.error('Error al registrar usuario.');
    }
  }

  /// Request password reset
  Future<AuthResult> resetPassword({required String email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call when backend implements password reset
      // await _apiClient.resetPassword(email: email);

      // Temporary mock
      await Future.delayed(const Duration(seconds: 2));

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
      return AuthResult.error('Error al enviar correo de recuperación.');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _currentUser = null;
    // TODO: Clear secure storage
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
}

/// Result of an authentication operation
class AuthResult {
  const AuthResult._({
    required this.success,
    this.errorMessage,
  });

  factory AuthResult.success() => const AuthResult._(success: true);
  
  factory AuthResult.error(String message) => AuthResult._(
        success: false,
        errorMessage: message,
      );

  final bool success;
  final String? errorMessage;
}
