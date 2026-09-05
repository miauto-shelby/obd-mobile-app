import 'package:flutter/material.dart';

import 'config/app_configuration.dart';
import 'features/auth/auth_models.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/home_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/session_storage.dart';

class ObdMobileApp extends StatefulWidget {
  ObdMobileApp({
    super.key,
    this.sessionStorage,
    AppConfiguration? configuration,
  }) : configuration = configuration ?? AppConfiguration.fromDartDefines();

  final SessionStorage? sessionStorage;
  final AppConfiguration configuration;

  @override
  State<ObdMobileApp> createState() => _ObdMobileAppState();
}

class _ObdMobileAppState extends State<ObdMobileApp> {
  late final AuthService _authService;
  AuthSession? _session;
  var _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      apiBaseUrl: widget.configuration.apiBaseUrl,
      googleClientId: widget.configuration.googleClientId,
      googleServerClientId: widget.configuration.googleServerClientId,
      sessionStorage: widget.sessionStorage,
    );
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _authService.restoreAndValidateSession();
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    } catch (error) {
      debugPrint(
        'No fue posible restaurar la sesión local: ${error.runtimeType}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringSession = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final session = await _authService.signInWithGoogle();
    if (!mounted) return;

    setState(() {
      _session = session;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
    } finally {
      if (mounted) {
        setState(() {
          _session = null;
        });
      }
    }
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
      home: _isRestoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : AnimatedSwitcher(
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
