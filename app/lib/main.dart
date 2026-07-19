import 'package:flutter/material.dart';

import 'state/auth_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/map/campus_map_screen.dart';

const _mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');

enum _HomeTab { map, events, groups }

class UNparcheApp extends StatelessWidget {
  const UNparcheApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFBF5F2);
    const ink = Color(0xFF263020);

    return MaterialApp(
      title: 'UNparche',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: background),
        scaffoldBackgroundColor: background,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = AuthProvider.of(context);

    return ValueListenableBuilder<AuthState>(
      valueListenable: authNotifier,
      builder: (context, authState, _) {
        if (authState.isLoading) {
          return const Scaffold(
            backgroundColor: CampusMapScreen._background,
            body: Center(
              child: CircularProgressIndicator(color: CampusMapScreen._ink),
            ),
          );
        }

        if (!authState.isAuthenticated) {
          return const LoginScreen();
        }

        return const CampusMapScreen();
      },
    );
  }
}

