import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('shows UNparche on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UNparcheApp());

    expect(find.text('UNparche'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Amigos'), findsNWidgets(2));
    expect(find.text('Mapa'), findsOneWidget);
  });
}
