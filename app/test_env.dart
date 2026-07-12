import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple script to test if .env file loads correctly
/// Run with: dart run test_env.dart
void main() async {
  print('🔍 Testing .env file loading...\n');
  
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env file loaded successfully!\n');
    
    print('📋 Environment Variables:');
    print('─' * 50);
    
    final accessToken = dotenv.env['ACCESS_TOKEN'];
    final apiBaseUrl = dotenv.env['API_BASE_URL'];
    final email = dotenv.env['EMAIL'];
    final googleAndroidId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];
    final googleIosId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
    
    print('ACCESS_TOKEN: ${accessToken != null ? '${accessToken.substring(0, 20)}...' : 'NOT SET'}');
    print('API_BASE_URL: ${apiBaseUrl ?? 'NOT SET'}');
    print('EMAIL: ${email ?? 'NOT SET'}');
    print('GOOGLE_ANDROID_CLIENT_ID: ${googleAndroidId != null ? '${googleAndroidId.substring(0, 20)}...' : 'NOT SET'}');
    print('GOOGLE_IOS_CLIENT_ID: ${googleIosId != null ? '${googleIosId.substring(0, 20)}...' : 'NOT SET'}');
    
    print('\n✨ All environment variables loaded successfully!');
    
  } catch (e) {
    print('❌ Error loading .env file: $e');
    print('\n💡 Make sure:');
    print('   1. You are in the app/ directory');
    print('   2. The .env file exists in app/.env');
    print('   3. You have run: flutter pub get');
  }
}
