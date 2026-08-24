import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'auth_models.dart';

class AuthService {
  AuthService({
    required this.apiBaseUrl,
    this.googleClientId,
    this.googleServerClientId,
  }) : _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile', 'openid'],
          clientId: googleClientId,
          serverClientId: googleServerClientId,
        );

  final String apiBaseUrl;
  final String? googleClientId;
  final String? googleServerClientId;
  final GoogleSignIn _googleSignIn;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<AuthSession> signInWithGoogle() async {
    if (googleServerClientId == null || googleServerClientId!.isEmpty) {
      throw const AuthException(
        'Falta GOOGLE_SERVER_CLIENT_ID. Debes pasar el Client ID web de Google.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthException('El inicio de sesion fue cancelado.');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
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

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/v1/auth/google'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestPayload.toJson()),
      );

      if (response.statusCode != 200) {
        debugPrint('Google auth response status: ${response.statusCode}');
        debugPrint('Google auth response body: ${response.body}');
        final errorBody = _safeDecode(response.body);
        throw AuthException(
          errorBody['message']?.toString() ??
              'No fue posible autenticar con Google.',
        );
      }

      final decoded = _safeDecode(response.body);
      return AuthSession.fromJson(decoded, requestPayload);
    } catch (error, stackTrace) {
      debugPrint('Google sign-in error type: ${error.runtimeType}');
      debugPrint('Google sign-in error value: $error');
      debugPrint('Google sign-in stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();

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

  void _logJwtClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        debugPrint('Google idToken no parece JWT valido.');
        return;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      if (claims is Map<String, dynamic>) {
        debugPrint('Google idToken aud: ${claims['aud']}');
        debugPrint('Google idToken iss: ${claims['iss']}');
        debugPrint('Google idToken azp: ${claims['azp']}');
        debugPrint('Google idToken email: ${claims['email']}');
      }
    } catch (error) {
      debugPrint('No se pudieron leer los claims del idToken: $error');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

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
