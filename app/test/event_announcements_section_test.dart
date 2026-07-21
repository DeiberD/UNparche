import 'package:app/models/event_announcement.dart';
import 'package:app/screens/events/event_announcements_section.dart';
import 'package:app/services/event_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses an event announcement returned by the API', () {
    final announcement = EventAnnouncement.fromJson({
      'id_anuncio': 19,
      'contenido': 'El salon cambio al edificio 401.',
      'fecha_publicacion': '2026-07-20T15:30:00.000Z',
      'id_autor': 7,
      'autor_nombre': 'Ana Organiza',
    });

    expect(announcement.id, 19);
    expect(announcement.content, 'El salon cambio al edificio 401.');
    expect(announcement.authorLabel, 'Ana Organiza');
    expect(announcement.publishedAt, DateTime.utc(2026, 7, 20, 15, 30));
  });

  testWidgets('attendees can read announcements but cannot publish them', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        canPublish: false,
        loader: () async => [
          EventAnnouncement.fromJson({
            'id_anuncio': 1,
            'contenido': 'La actividad comienza media hora antes.',
            'id_autor': 8,
            'autor_nombre': 'Organizador UN',
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('La actividad comienza media hora antes.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Publicar anuncio'), findsNothing);
  });

  testWidgets('organizer can publish an announcement from the event detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        canPublish: true,
        loader: () async => const [],
        publisher: (content) async => EventAnnouncement(
          id: 2,
          content: content,
          publishedAt: DateTime(2026, 7, 20, 12),
          authorId: 1,
          authorName: 'Organizador UN',
          authorNickname: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este evento aun no tiene anuncios.'), findsOneWidget);
    await tester.tap(find.byTooltip('Publicar anuncio'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'La ubicacion cambio al auditorio principal.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
    await tester.pumpAndSettle();

    expect(
      find.text('La ubicacion cambio al auditorio principal.'),
      findsOneWidget,
    );
    expect(find.text('Anuncio publicado.'), findsOneWidget);
    expect(find.byTooltip('Publicar anuncio'), findsOneWidget);
  });

  testWidgets(
    'a new announcement replaces the previous one in the event detail',
    (tester) async {
      await tester.pumpWidget(
        _testApp(
          canPublish: true,
          loader: () async => [
            const EventAnnouncement(
              id: 3,
              content: 'Anuncio existente',
              publishedAt: null,
              authorId: 1,
              authorName: 'Organizador UN',
              authorNickname: null,
            ),
          ],
          publisher: (content) async => EventAnnouncement(
            id: 4,
            content: content,
            publishedAt: DateTime(2026, 7, 20, 13),
            authorId: 1,
            authorName: 'Organizador UN',
            authorNickname: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anuncio existente'), findsOneWidget);
      await tester.tap(find.byTooltip('Publicar anuncio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Anuncio mas reciente');
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();

      expect(find.text('Anuncio existente'), findsNothing);
      expect(find.text('Anuncio mas reciente'), findsOneWidget);
    },
  );
}

Widget _testApp({
  required bool canPublish,
  required AnnouncementLoader loader,
  AnnouncementPublisher? publisher,
}) {
  return MaterialApp(
    home: Scaffold(
      body: EventAnnouncementsSection(
        eventId: 12,
        currentUserId: 1,
        canPublish: canPublish,
        eventApiClient: EventApiClient(baseUrl: 'http://127.0.0.1:8787'),
        loader: loader,
        publisher: publisher,
      ),
    ),
  );
}
