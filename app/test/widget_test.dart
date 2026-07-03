import 'package:flutter/material.dart';
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

  testWidgets('opens the HU-27 create event form', (WidgetTester tester) async {
    await tester.pumpWidget(const UNparcheApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo evento'), findsOneWidget);
    expect(find.text('Titulo del evento'), findsOneWidget);
    expect(find.text('Descripcion'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Ubicacion'), findsOneWidget);
    expect(find.text('Tipo de evento'), findsOneWidget);
    expect(find.text('Visibilidad'), findsOneWidget);
    expect(find.text('Chat del evento'), findsOneWidget);
    expect(find.text('Publicar evento'), findsOneWidget);
  });
}
