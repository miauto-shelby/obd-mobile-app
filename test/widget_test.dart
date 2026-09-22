import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:obd_mobile_app/src/app.dart';
import 'package:obd_mobile_app/src/features/auth/auth_models.dart';
import 'package:obd_mobile_app/src/features/auth/home_page.dart';
import 'package:obd_mobile_app/src/features/auth/session_storage.dart';

class _EmptySessionStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}
}

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ObdMobileApp(sessionStorage: _EmptySessionStorage()),
    );
    await tester.pump();

    expect(find.text('MY AUTO'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('shows the refreshed authenticated dashboard', (
    WidgetTester tester,
  ) async {
    const session = AuthSession(
      request: GoogleAuthRequest(
        idToken: '',
        deviceId: 'test-device',
        deviceName: 'Test device',
        platform: 'ANDROID',
        appVersion: '1.0.0',
      ),
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresIn: 900,
      tokenType: 'Bearer',
      user: AuthUser(
        id: 'user-1',
        firstName: 'Sebastián',
        lastName: 'Fajardo',
        email: 'sebastian@example.com',
        photoUrl: '',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          session: session,
          onLogout: () async {},
          apiBaseUrl: 'http://127.0.0.1:8080',
        ),
      ),
    );

    expect(find.text('Hola, Sebastián Fajardo'), findsOneWidget);
    expect(find.text('Conectar OBD2'), findsNWidgets(2));
    expect(find.text('Estado del vehículo'), findsOneWidget);
    expect(find.text('Sesión protegida'), findsOneWidget);
  });

  testWidgets('opens the profile and closes the session from the menu', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var logoutCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          session: _session,
          onLogout: () async => logoutCalled = true,
          apiBaseUrl: 'http://127.0.0.1:8080',
        ),
      ),
    );

    final profileNavigation = find.ancestor(
      of: find.text('Sesión protegida'),
      matching: find.byType(InkWell),
    );
    await tester.tap(profileNavigation);
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('sebastian@example.com'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(logoutCalled, isTrue);
  });

  testWidgets('opens the OBD2 diagnostic preparation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          session: _session,
          onLogout: () async {},
          apiBaseUrl: 'http://127.0.0.1:8080',
        ),
      ),
    );

    await tester.tap(find.text('Conectar OBD2').first);
    await tester.pumpAndSettle();
    expect(find.text('Diagnóstico OBD2'), findsOneWidget);
    expect(find.text('Diagnóstico en preparación'), findsOneWidget);
  });
}

const _session = AuthSession(
  request: GoogleAuthRequest(
    idToken: '',
    deviceId: 'test-device',
    deviceName: 'Test device',
    platform: 'ANDROID',
    appVersion: '1.0.0',
  ),
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: 900,
  tokenType: 'Bearer',
  user: AuthUser(
    id: 'user-1',
    firstName: 'Sebastián',
    lastName: 'Fajardo',
    email: 'sebastian@example.com',
    photoUrl: '',
  ),
);
