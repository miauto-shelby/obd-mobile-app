import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'auth_models.dart';
import 'session_storage.dart';

class AuthService {
  AuthService({
    required this.apiBaseUrl,
    this.googleClientId,
    this.googleServerClientId,
    SessionStorage? sessionStorage,
  }) : _googleSignIn = GoogleSignIn(
         scopes: const ['email', 'profile', 'openid'],
         clientId: googleClientId,
         serverClientId: googleServerClientId,
       ),
       _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final String apiBaseUrl;
  final String? googleClientId;
  final String? googleServerClientId;
  final GoogleSignIn _googleSignIn;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final SessionStorage _sessionStorage;

  Future<AuthSession> signInWithGoogle() async {
    if (googleServerClientId == null || googleServerClientId!.isEmpty) {
      throw const AuthException(
        AuthErrorKind.request,
        'Falta GOOGLE_SERVER_CLIENT_ID. Debes pasar el Client ID web de Google.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthException(
          AuthErrorKind.google,
          'El inicio de sesión fue cancelado.',
        );
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          AuthErrorKind.google,
          'No fue posible obtener el token de Google. Revisa el SHA-1, el package name y que GOOGLE_SERVER_CLIENT_ID sea el Client ID web.',
        );
      }
      _logJwtClaims(idToken);

      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = await _resolveDeviceInfo();

      final requestPayload = GoogleAuthRequest(
        idToken: idToken,
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        platform: deviceInfo.platform,
        appVersion: packageInfo.version,
      );

      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/v1/auth/google'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('Google auth response status: ${response.statusCode}');
        throw _apiError(_safeDecode(response.body), response.statusCode);
      }

      final decoded = _safeDecode(response.body);
      final session = AuthSession.fromJson(decoded, requestPayload);
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        throw const AuthException(
          AuthErrorKind.server,
          'El servidor no devolvió una sesión válida. Inténtalo de nuevo.',
        );
      }
      await _sessionStorage.write(session);
      return session;
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthErrorKind.network,
        'La conexión tardó demasiado. Verifica tu red e inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthErrorKind.network,
        'No fue posible conectarse al servidor. Verifica tu red e inténtalo de nuevo.',
      );
    } on PlatformException catch (error) {
      debugPrint('Google sign-in platform error code: ${error.code}');
      throw const AuthException(
        AuthErrorKind.google,
        'No fue posible iniciar sesión con Google. Inténtalo de nuevo.',
      );
    } catch (error) {
      debugPrint('Google sign-in unexpected error type: ${error.runtimeType}');
      throw const AuthException(
        AuthErrorKind.unknown,
        'Ocurrió un error inesperado al iniciar sesión. Inténtalo de nuevo.',
      );
    }
  }

  Future<AuthSession?> restoreSession() => _sessionStorage.read();

  Future<void> signOut() async {
    final session = await _sessionStorage.read();
    try {
      if (session != null) {
        await http
            .post(
              Uri.parse('$apiBaseUrl/api/v1/auth/logout'),
              headers: {
                'Authorization': '${session.tokenType} ${session.accessToken}',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } on TimeoutException {
      debugPrint('Remote logout timed out; clearing local session.');
    } on http.ClientException {
      debugPrint('Remote logout network error; clearing local session.');
    } finally {
      await _sessionStorage.clear();
      try {
        await _googleSignIn.signOut();
      } on PlatformException catch (error) {
        debugPrint('Google sign-out platform error code: ${error.code}');
      }
    }
  }

  Future<AuthSession?> restoreAndValidateSession() async {
    final stored = await _sessionStorage.read();
    if (stored == null) {
      return null;
    }

    try {
      final meResponse = await _getCurrentUser(stored);
      if (meResponse.statusCode == 200) {
        final session = stored.copyWith(
          user: _userFromMe(_safeDecode(meResponse.body)),
        );
        await _sessionStorage.write(session);
        return session;
      }

      if (meResponse.statusCode != 401) {
        return stored;
      }

      return _refreshStoredSession(stored);
    } catch (error) {
      debugPrint(
        'No fue posible validar la sesión remota: ${error.runtimeType}',
      );
      return stored;
    }
  }

  Future<http.Response> _getCurrentUser(AuthSession session) {
    return http
        .get(
          Uri.parse('$apiBaseUrl/api/v1/auth/me'),
          headers: {
            'Authorization': '${session.tokenType} ${session.accessToken}',
          },
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<AuthSession?> _refreshStoredSession(AuthSession session) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/api/v1/auth/refresh'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'refreshToken': session.refreshToken,
            'appVersion': session.request.appVersion,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      await _sessionStorage.clear();
      return null;
    }

    final body = _safeDecode(response.body);
    final refreshed = session.copyWith(
      accessToken: body['accessToken']?.toString(),
      refreshToken: body['refreshToken']?.toString(),
      expiresIn: body['expiresIn'] is int
          ? body['expiresIn'] as int
          : int.tryParse(body['expiresIn']?.toString() ?? ''),
    );
    if (refreshed.accessToken.isEmpty || refreshed.refreshToken.isEmpty) {
      await _sessionStorage.clear();
      return null;
    }
    await _sessionStorage.write(refreshed);
    return refreshed;
  }

  AuthUser _userFromMe(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }

  Future<_DeviceSnapshot> _resolveDeviceInfo() async {
    if (kIsWeb) {
      final web = await _deviceInfoPlugin.webBrowserInfo;
      return _DeviceSnapshot(
        deviceId: web.vendor ?? web.userAgent ?? 'web-device',
        deviceName: web.userAgent ?? 'WEB',
        platform: 'WEB',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = await _deviceInfoPlugin.androidInfo;
        return _DeviceSnapshot(
          deviceId: android.id,
          deviceName: '${android.brand} ${android.model}'.trim(),
          platform: 'ANDROID',
        );
      case TargetPlatform.iOS:
        final ios = await _deviceInfoPlugin.iosInfo;
        return _DeviceSnapshot(
          deviceId: ios.identifierForVendor ?? 'ios-device',
          deviceName: ios.name,
          platform: 'IOS',
        );
      case TargetPlatform.macOS:
        final mac = await _deviceInfoPlugin.macOsInfo;
        return _DeviceSnapshot(
          deviceId: mac.systemGUID ?? 'mac-device',
          deviceName: mac.computerName,
          platform: 'MACOS',
        );
      case TargetPlatform.windows:
        final windows = await _deviceInfoPlugin.windowsInfo;
        return _DeviceSnapshot(
          deviceId: windows.deviceId,
          deviceName: windows.computerName,
          platform: 'WINDOWS',
        );
      case TargetPlatform.linux:
        final linux = await _deviceInfoPlugin.linuxInfo;
        return _DeviceSnapshot(
          deviceId: linux.machineId ?? linux.id,
          deviceName: linux.prettyName,
          platform: 'LINUX',
        );
      case TargetPlatform.fuchsia:
        return const _DeviceSnapshot(
          deviceId: 'fuchsia-device',
          deviceName: 'Fuchsia',
          platform: 'FUCHSIA',
        );
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  AuthException _apiError(Map<String, dynamic> body, int statusCode) {
    final code = body['code']?.toString();

    switch (code) {
      case 'USER_DISABLED':
        return const AuthException(
          AuthErrorKind.account,
          'Tu cuenta está deshabilitada. Comunícate con soporte.',
        );
      case 'INVALID_GOOGLE_TOKEN':
      case 'GOOGLE_TOKEN_EXPIRED':
        return const AuthException(
          AuthErrorKind.google,
          'Google no pudo validar tu sesión. Vuelve a iniciar sesión.',
        );
      case 'REFRESH_TOKEN_EXPIRED':
      case 'REFRESH_TOKEN_INVALID':
      case 'REFRESH_TOKEN_REUSED':
      case 'INVALID_ACCESS_TOKEN':
      case 'TOKEN_EXPIRED':
      case 'SESSION_NOT_FOUND':
        return const AuthException(
          AuthErrorKind.session,
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      case 'VALIDATION_ERROR':
        return const AuthException(
          AuthErrorKind.request,
          'No se pudo procesar la solicitud. Inténtalo de nuevo.',
        );
    }

    if (statusCode >= 500) {
      return const AuthException(
        AuthErrorKind.server,
        'El servidor no está disponible en este momento. Inténtalo más tarde.',
      );
    }

    return const AuthException(
      AuthErrorKind.unknown,
      'No fue posible iniciar sesión. Inténtalo de nuevo.',
    );
  }

  void _logJwtClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        debugPrint('Google idToken no parece JWT válido.');
        return;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      if (claims is Map<String, dynamic>) {
        debugPrint('Google idToken claims format is valid.');
      }
    } catch (_) {
      debugPrint('No se pudieron leer los claims del idToken.');
    }
  }
}

enum AuthErrorKind {
  network,
  google,
  account,
  session,
  request,
  server,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.kind, this.message);

  final AuthErrorKind kind;

  final String message;

  @override
  String toString() => message;
}

class _DeviceSnapshot {
  const _DeviceSnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
}
