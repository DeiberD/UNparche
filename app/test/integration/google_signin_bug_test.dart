import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/auth_service.dart';
import 'package:app/services/api_client.dart';

/// Bug Condition Exploration Test for Google Sign-In
/// 
/// **IMPORTANT**: This test is EXPECTED TO FAIL on unfixed code.
/// Failure confirms the bug exists. DO NOT attempt to fix the code yet.
/// 
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6**
/// 
/// This test encodes the expected behavior from Requirements Section 2:
/// - Google Sign-In flow should complete successfully
/// - Valid idToken should be obtained
/// - User should be authenticated
/// - Error messages should be specific, not generic
/// 
/// After the fix is implemented, this test should PASS, confirming the bug is resolved.

void main() {
  group('Bug Condition Exploration Tests - Google Sign-In', () {
    setUpAll(() async {
      // Load environment variables for testing
      await dotenv.load(fileName: '.env');
    });

    test('Test Case 1: Missing GOOGLE_WEB_CLIENT_ID causes idToken = null', () async {
      // **Bug Condition**: When GOOGLE_WEB_CLIENT_ID is not configured properly,
      // the idToken should be null and the flow should fail.
      //
      // **Expected Behavior (after fix)**: The system should detect missing config
      // and return a specific error message explaining the issue.
      
      // Get current configuration
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      
      // Document current state
      print('[Test Case 1] GOOGLE_WEB_CLIENT_ID = ${webClientId != null ? "PRESENT (${webClientId.length} chars)" : "NULL"}');
      
      // The bug manifests when:
      // 1. User presses "Continuar con Google"
      // 2. GoogleSignIn initializes without proper serverClientId
      // 3. OAuth flow fails to generate idToken
      // 4. Application shows generic "Error desconocido"
      
      // **EXPECTED FAILURE ON UNFIXED CODE**:
      // - If webClientId is missing/empty, the test should detect this configuration issue
      // - If webClientId is present but SHA-1 is not registered, idToken will be null
      // - The current code shows generic error messages instead of specific ones
      
      expect(
        webClientId != null && webClientId.isNotEmpty,
        isTrue,
        reason: 'GOOGLE_WEB_CLIENT_ID must be configured for Google Sign-In to work. '
            'After fix, this should be validated and return specific error message.',
      );
      
      print('[Test Case 1] Configuration check passed - GOOGLE_WEB_CLIENT_ID is present');
    });

    test('Test Case 2: Invalid SHA-1 configuration causes OAuth failure', () async {
      // **Bug Condition**: When SHA-1 fingerprint is not registered in Google Cloud Console,
      // the OAuth flow fails and idToken is null.
      //
      // **Expected Behavior (after fix)**: The system should detect null idToken
      // and return a specific error message guiding the user to check SHA-1 registration.
      
      print('[Test Case 2] Testing OAuth flow behavior with current configuration...');
      
      // Note: We cannot directly test SHA-1 registration in a unit test,
      // but we can verify that the code handles null idToken appropriately.
      
      // Create AuthService
      final authService = AuthService();
      
      // Attempt Google Sign-In
      // **EXPECTED FAILURE ON UNFIXED CODE**:
      // - If SHA-1 is not registered, googleUser.authentication.idToken will be null
      // - Current code may not handle this properly or show generic error
      // - After fix, should show specific error: "No se pudo obtener token de Google"
      
      final result = await authService.signInWithGoogle();
      
      // Document the result
      print('[Test Case 2] Sign-In Result:');
      print('  - success: ${result.success}');
      print('  - errorMessage: ${result.errorMessage}');
      
      // **THIS ASSERTION WILL FAIL ON UNFIXED CODE** (this is correct!)
      // On unfixed code, result.success may be false with generic error message
      // On fixed code, this should succeed OR return specific error message
      expect(
        result.success || (result.errorMessage != null && !result.errorMessage!.contains('Error desconocido')),
        isTrue,
        reason: 'Google Sign-In should either succeed OR return a SPECIFIC error message (not "Error desconocido"). '
            'Current behavior shows generic errors. After fix, errors should be descriptive.',
      );
    });

    test('Test Case 3: Backend token verification failure', () async {
      // **Bug Condition**: When backend fails to verify the token or returns error,
      // the application shows generic "Error desconocido" message.
      //
      // **Expected Behavior (after fix)**: Backend should verify tokens properly
      // and return specific error messages for different failure scenarios.
      
      print('[Test Case 3] Testing backend token verification...');
      
      final apiClient = ApiClient();
      
      // Test with an obviously invalid token
      final invalidToken = 'invalid.token.here';
      
      try {
        await apiClient.loginWithGoogle(idToken: invalidToken);
        fail('Should throw an exception for invalid token');
      } on ApiException catch (e) {
        print('[Test Case 3] API Exception caught:');
        print('  - message: ${e.message}');
        print('  - statusCode: ${e.statusCode}');
        
        // **THIS ASSERTION WILL FAIL ON UNFIXED CODE** (this is correct!)
        // On unfixed code: "Error desconocido" or generic message
        // On fixed code: Specific message like "Token de Google inválido o mal formado"
        expect(
          e.message != 'Error desconocido',
          isTrue,
          reason: 'Backend should return SPECIFIC error messages for token verification failures, '
              'not generic "Error desconocido". After fix, should see messages like '
              '"Token de Google inválido o mal formado" or "Token de Google expirado".',
        );
      } catch (e) {
        print('[Test Case 3] Unexpected error type: ${e.runtimeType}');
        print('  - error: $e');
        
        // **THIS WILL FAIL ON UNFIXED CODE** - confirms error handling is inadequate
        fail('Should throw ApiException with specific message, got: $e');
      }
    });

    test('Test Case 4: Generic error handling produces non-specific messages', () async {
      // **Bug Condition**: Current error handling shows "Error desconocido" for various failures.
      //
      // **Expected Behavior (after fix)**: Each error scenario should have a specific,
      // actionable error message that helps the user understand what went wrong.
      
      print('[Test Case 4] Testing error message specificity...');
      
      final authService = AuthService();
      
      // Attempt sign-in to capture any errors
      final result = await authService.signInWithGoogle();
      
      print('[Test Case 4] Sign-In Result:');
      print('  - success: ${result.success}');
      print('  - errorMessage: ${result.errorMessage}');
      
      if (!result.success && result.errorMessage != null) {
        // Document the error message we received
        final errorMsg = result.errorMessage!;
        
        // Check if error message is generic
        final isGeneric = errorMsg.contains('Error desconocido') ||
            errorMsg.contains('desconocido') ||
            errorMsg == 'Error';
        
        print('[Test Case 4] Error message is ${isGeneric ? "GENERIC" : "SPECIFIC"}');
        
        // **THIS ASSERTION WILL FAIL ON UNFIXED CODE** (this is correct!)
        // On unfixed code: Generic "Error desconocido"
        // On fixed code: Specific messages explaining what went wrong
        expect(
          !isGeneric,
          isTrue,
          reason: 'Error messages should be SPECIFIC and actionable, not generic "Error desconocido". '
              'After fix, should see messages like:\n'
              '  - "Inicio de sesión cancelado por el usuario"\n'
              '  - "No se pudo obtener el token de Google"\n'
              '  - "Error de conexión, verifica tu red"\n'
              '  - "Token de Google inválido o mal formado"\n'
              'Current message: "$errorMsg"',
        );
      } else if (result.success) {
        // If sign-in succeeded, that means the configuration is correct
        // and the bug may already be fixed
        print('[Test Case 4] Sign-in succeeded - configuration appears correct');
        print('[Test Case 4] This may indicate the bug is already fixed OR SHA-1 is properly registered');
      }
    });
  });

  group('Bug Condition - Expected Behavior Properties', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    test('Property: Google Sign-In should complete successfully with valid config', () async {
      // **Property from Design.md**: For any input where the bug condition holds,
      // the fixed handleGoogleSignIn function SHALL successfully complete the OAuth flow.
      //
      // **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 2.8, 2.9, 2.10**
      
      print('[Property Test] Testing complete Google Sign-In flow...');
      
      final authService = AuthService();
      final result = await authService.signInWithGoogle();
      
      print('[Property Test] Complete Flow Result:');
      print('  - success: ${result.success}');
      print('  - errorMessage: ${result.errorMessage}');
      
      if (result.success) {
        print('[Property Test] ✓ Google Sign-In completed successfully');
        print('[Property Test] ✓ User authenticated: ${authService.currentUser?.email}');
        
        // Verify user data
        expect(authService.currentUser, isNotNull, reason: 'User should be authenticated after successful sign-in');
        expect(authService.currentUser!.email, contains('@unal.edu.co'), 
            reason: 'User email should be institutional (@unal.edu.co)');
        
        print('[Property Test] ✓ All expected behavior properties satisfied');
      } else {
        // **EXPECTED TO FAIL ON UNFIXED CODE**
        print('[Property Test] ✗ Google Sign-In failed: ${result.errorMessage}');
        print('[Property Test] This failure confirms the bug exists');
        
        // Document the failure
        expect(result.success, isTrue,
            reason: 'EXPECTED FAILURE: Google Sign-In flow should complete successfully '
                'but currently fails due to the bug. Error: ${result.errorMessage}\n'
                'After fix is implemented, this test should PASS.');
      }
    });

    test('Property: idToken should be non-null after successful authentication', () async {
      // **Property**: After successful Google authentication, idToken MUST be a valid JWT string.
      //
      // **Bug Condition**: Current code may return null idToken due to:
      // - Missing serverClientId configuration
      // - SHA-1 not registered in Google Cloud Console
      
      print('[Property Test] Testing idToken obtention...');
      
      final authService = AuthService();
      
      // The AuthService doesn't expose idToken directly, but we can check if
      // authentication succeeded (which implies idToken was obtained)
      final result = await authService.signInWithGoogle();
      
      if (result.success) {
        // If successful, idToken must have been obtained and sent to backend
        print('[Property Test] ✓ Authentication successful (implies idToken was obtained)');
        expect(authService.isAuthenticated, isTrue);
      } else {
        // **EXPECTED TO FAIL ON UNFIXED CODE**
        print('[Property Test] ✗ Authentication failed (idToken likely null)');
        print('[Property Test] Error: ${result.errorMessage}');
        
        // This documents the bug: idToken is null or OAuth flow fails
        expect(result.success, isTrue,
            reason: 'EXPECTED FAILURE: idToken should be obtained but is likely null '
                'due to misconfiguration (missing serverClientId or SHA-1 not registered). '
                'Error: ${result.errorMessage}');
      }
    });

    test('Property: Error messages should be specific and actionable', () async {
      // **Property**: For any error during Google Sign-In, the error message
      // SHALL be specific and guide the user on how to resolve it.
      //
      // **Bug Condition**: Current code shows generic "Error desconocido"
      
      print('[Property Test] Testing error message quality...');
      
      // Test with invalid API client to force an error
      final apiClient = ApiClient();
      
      try {
        // Use an obviously malformed token to trigger an error
        await apiClient.loginWithGoogle(idToken: 'malformed');
        fail('Should have thrown an exception');
      } on ApiException catch (e) {
        print('[Property Test] Error message: "${e.message}"');
        
        // **THIS WILL FAIL ON UNFIXED CODE**
        final isSpecific = !e.message.contains('Error desconocido') &&
            !e.message.contains('desconocido') &&
            e.message.length > 10;  // Not just "Error"
        
        print('[Property Test] Error message is ${isSpecific ? "SPECIFIC" : "GENERIC"}');
        
        expect(isSpecific, isTrue,
            reason: 'EXPECTED FAILURE: Error messages should be specific and actionable, '
                'not generic "Error desconocido". Current: "${e.message}"');
      }
    });
  });
}
