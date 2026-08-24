import 'package:flutter_test/flutter_test.dart';

import 'package:obd_mobile_app/src/app.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ObdMobileApp());
    expect(find.text('MY AUTO'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
