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
    final startedAt = DateTime.now();
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
      const minimumSplashDuration = Duration(milliseconds: 650);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minimumSplashDuration) {
        await Future<void>.delayed(minimumSplashDuration - elapsed);
      }
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
          ? const _BrandLoadingScreen()
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
                      apiBaseUrl: widget.configuration.apiBaseUrl,
                    ),
            ),
    );
  }
}

class _BrandLoadingScreen extends StatelessWidget {
  const _BrandLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LargeBrandLogo(),
              SizedBox(height: 18),
              Text(
                'MY AUTO',
                style: TextStyle(
                  color: Color(0xFF767676),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFFD80000),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeBrandLogo extends StatelessWidget {
  const _LargeBrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      height: 218,
      padding: const EdgeInsets.all(9),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFD80000), width: 6),
        ),
      ),
      child: ClipOval(
        child: Image.asset('assets/images/brand_logo.png', fit: BoxFit.contain),
      ),
    );
  }
}
