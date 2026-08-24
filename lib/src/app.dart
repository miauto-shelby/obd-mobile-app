import 'package:flutter/material.dart';

import 'features/auth/auth_models.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/home_page.dart';
import 'features/auth/login_page.dart';

class ObdMobileApp extends StatefulWidget {
  const ObdMobileApp({super.key});

  @override
  State<ObdMobileApp> createState() => _ObdMobileAppState();
}

class _ObdMobileAppState extends State<ObdMobileApp> {
  static const String _defaultApiBaseUrl = 'http://127.0.0.1:8080';
  static const String _defaultGoogleServerClientId =
      '1001362850388-h14mgg5umq5cdopv2qdbkj3fud4u31th.apps.googleusercontent.com';

  late final AuthService _authService = AuthService(
    apiBaseUrl: _envOrDefault('API_BASE_URL', _defaultApiBaseUrl),
    googleClientId: _optionalEnv('GOOGLE_CLIENT_ID'),
    googleServerClientId:
        _optionalEnv('GOOGLE_SERVER_CLIENT_ID') ?? _defaultGoogleServerClientId,
  );
  AuthSession? _session;

  String _envOrDefault(String name, String defaultValue) {
    final value = String.fromEnvironment(name);
    return value.isEmpty ? defaultValue : value;
  }

  String? _optionalEnv(String name) {
    final value = String.fromEnvironment(name);
    return value.isEmpty ? null : value;
  }

  Future<void> _handleGoogleLogin() async {
    final session = await _authService.signInWithGoogle();
    if (!mounted) return;

    setState(() {
      _session = session;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;

    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00A3FF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Auto',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF07111F),
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _session == null
            ? LoginPage(
                key: const ValueKey('login-page'),
                onGoogleLogin: _handleGoogleLogin,
              )
            : HomePage(
                key: const ValueKey('home-page'),
                session: _session!,
                onLogout: _handleLogout,
              ),
      ),
    );
  }
}
