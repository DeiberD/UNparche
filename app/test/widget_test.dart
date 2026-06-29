import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('shows UNparche on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UNparcheApp());

    expect(find.text('UNparche'), findsNWidgets(2));
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });
}
