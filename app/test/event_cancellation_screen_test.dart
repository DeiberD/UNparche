import 'package:app/models/event_announcement.dart';
import 'package:app/models/event_summary.dart';
import 'package:app/screens/events/event_detail_screen.dart';
import 'package:app/services/event_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('organizer confirms cancellation of a future event', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _FakeEventApiClient();
    EventSummary? updatedEvent;
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(
          event: _futureEvent(organizerId: 1),
          eventApiClient: client,
          currentUserId: 1,
          onAttendanceChanged: (event) => updatedEvent = event,
          onDeleted: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(OutlinedButton, 'Cancelar evento'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar evento'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Dejará de mostrarse como activo'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sí, cancelar'));
    await tester.pumpAndSettle();

    expect(client.cancelledEventId, 8);
    expect(updatedEvent?.status, 'CANCELADO');
    expect(updatedEvent?.chatEnabled, isFalse);
    expect(
      find.textContaining('fue cancelado por su organizador'),
      findsOneWidget,
    );
    expect(find.text('Cancelar evento'), findsNothing);
  });

  testWidgets('a user who is not the organizer cannot cancel the event', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(
          event: _futureEvent(organizerId: 5),
          eventApiClient: _FakeEventApiClient(),
          currentUserId: 1,
          onAttendanceChanged: (_) {},
          onDeleted: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelar evento'), findsNothing);
  });
}

EventSummary _futureEvent({required int organizerId}) {
  final start = DateTime.now().add(const Duration(days: 2));
  return EventSummary.fromJson({
    'id_evento': 8,
    'titulo': 'Taller futuro',
    'descripcion': 'Actividad por realizarse',
    'fecha_inicio': start.toIso8601String(),
    'duracion_minutos': 90,
    'fecha_fin': start.add(const Duration(minutes: 90)).toIso8601String(),
    'latitud': 4.6382,
    'longitud': -74.084,
    'visibilidad': 'PUBLICA',
    'chat_habilitado': 1,
    'estado': 'PROGRAMADO',
    'id_organizador': organizerId,
    'organizador_nombre': 'Organizador UN',
    'id_tipo_evento': 1,
    'tipo_evento_nombre': 'ACADEMICO',
  });
}

class _FakeEventApiClient extends EventApiClient {
  _FakeEventApiClient() : super(baseUrl: 'http://127.0.0.1:8787');

  int? cancelledEventId;

  @override
  Future<List<EventAnnouncement>> fetchAnnouncements({required int eventId}) {
    return Future.value(const []);
  }

  @override
  Future<void> cancelEvent({
    required int eventId,
    required int organizerId,
  }) async {
    cancelledEventId = eventId;
  }
}
