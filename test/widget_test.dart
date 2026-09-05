import 'package:flutter_test/flutter_test.dart';

import 'package:obd_mobile_app/src/app.dart';
import 'package:obd_mobile_app/src/features/auth/auth_models.dart';
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
}
