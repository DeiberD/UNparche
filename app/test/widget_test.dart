import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/event_cluster_data.dart';
import 'package:app/state/location_picker_state.dart';
import 'package:app/campus_location_map_facade.dart';
import 'package:app/models/event_summary.dart';
import 'package:app/state/auth_state.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/events/attendance_history_screen.dart';

Widget _authenticatedApp() {
  final notifier = AuthNotifier.withState(
    AuthState(
      token: 'test-token',
      isLoading: false,
      currentUser: User(
        id: 1,
        correoInstitucional: 'test@unal.edu.co',
        nombre: 'Test',
        apellido: 'User',
      ),
    ),
  );
  return AuthProvider(notifier: notifier, child: const UNparcheApp());
}

void main() {
  test('location picker states preserve valid workflow transitions', () {
    const selection = LocationSelection(
      latitude: 4.6382,
      longitude: -74.084,
      label: 'Campus UNAL',
    );

    const initial = AwaitingLocationState();
    expect(initial.canConfirm, isFalse);

    final selected = initial.onLocationSelected(selection);
    expect(selected, isA<LocationSelectedState>());
    expect(selected.selection, selection);
    expect(selected.canConfirm, isTrue);
    expect(selected.message, 'Campus UNAL');

    final failed = selected.onMapFailure('Mapbox no disponible');
    expect(failed, isA<LocationPickerErrorState>());
    expect(failed.hasError, isTrue);
    expect(failed.selection, selection);

    final recovered = failed.onMapReady();
    expect(recovered, isA<LocationSelectedState>());
    expect(recovered.selection, selection);
    expect(recovered.hasError, isFalse);
  });

  test('builds clusterable GeoJSON only for events with a location', () {
    final eventWithLocation = _event(
      id: 7,
      latitude: 4.638,
      longitude: -74.084,
    );
    final eventWithoutLocation = _event(id: 8);

    final geoJson = buildEventClusterFeatureCollection([
      eventWithLocation,
      eventWithoutLocation,
    ]);
    final features = geoJson['features']! as List<Map<String, dynamic>>;

    expect(features, hasLength(1));
    expect(features.single['id'], 'event-7');
    expect(features.single['properties'], containsPair('event_key', 'event-7'));
    expect(
      (features.single['geometry'] as Map<String, dynamic>)['coordinates'],
      [-74.084, 4.638],
    );
  });

  test('identifies lifecycle-archived events in attendance history', () {
    final event = EventSummary.fromJson({
      'id_evento': 24,
      'titulo': 'Evento recordado',
      'fecha_fin': '2026-06-20T16:00:00.000Z',
      'fecha_eliminacion': '2026-06-21T16:00:00.000Z',
      'estado': 'FINALIZADO',
      'estado_asistencia': 'CONFIRMADA',
    });

    expect(event.isArchived, isTrue);
    expect(event.hasConfirmedAttendance, isTrue);
    expect(event.archivedAt, DateTime.utc(2026, 6, 21, 16));
  });

  testWidgets('HU-24 shows an empty attended-event history message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceHistoryScreen(
          currentUserId: 1,
          historyLoader: (_) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historial de eventos'), findsOneWidget);
    expect(find.text('No hay eventos en tu historial'), findsOneWidget);
    expect(
      find.text(
        'Los eventos pasados a los que hayas asistido apareceran aqui.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('HU-24 opens an archived attended event detail', (
    WidgetTester tester,
  ) async {
    final event = EventSummary.fromJson({
      'id_evento': 24,
      'titulo': 'Encuentro cultural',
      'descripcion': 'Actividad archivada del campus',
      'fecha_inicio': '2026-06-20T14:00:00.000Z',
      'duracion_minutos': 120,
      'fecha_fin': '2026-06-20T16:00:00.000Z',
      'fecha_eliminacion': '2026-06-21T16:00:00.000Z',
      'latitud': 4.6382,
      'longitud': -74.084,
      'visibilidad': 'PUBLICA',
      'chat_habilitado': 0,
      'estado': 'FINALIZADO',
      'id_organizador': 8,
      'organizador_nombre': 'Organizador UN',
      'id_tipo_evento': 2,
      'tipo_evento_nombre': 'CULTURAL',
      'estado_asistencia': 'CONFIRMADA',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceHistoryScreen(
          currentUserId: 1,
          historyLoader: (_) async => [event],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 evento recordado'), findsOneWidget);
    expect(find.text('Encuentro cultural'), findsOneWidget);

    await tester.tap(find.text('Encuentro cultural'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del evento'), findsOneWidget);
    expect(find.text('Actividad archivada del campus'), findsOneWidget);
    expect(
      find.textContaining('fue archivado por su ciclo de vida'),
      findsOneWidget,
    );
  });

  testWidgets('shows UNparche on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(_authenticatedApp());

    expect(find.text('UNparche'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('opens the HU-27 create event form', (WidgetTester tester) async {
    await tester.pumpWidget(_authenticatedApp());

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

EventSummary _event({int? id, double? latitude, double? longitude}) {
  return EventSummary(
    id: id,
    title: 'Evento',
    description: 'Descripcion',
    start: DateTime(2026, 7, 10, 10),
    durationMinutes: 60,
    end: DateTime(2026, 7, 10, 11),
    latitude: latitude,
    longitude: longitude,
    visibility: 'PUBLICA',
    organizerId: 1,
    organizerName: 'Organizador',
    organizerEmail: null,
    organizerCareer: null,
    organizerInfo: null,
    groupId: null,
    chatEnabled: false,
    groupName: null,
    groupDescription: null,
    groupCategory: null,
    groupIsOfficial: null,
    groupVerificationStatus: null,
    eventTypeId: 1,
    eventTypeName: 'Academico',
    status: 'PROGRAMADO',
    attendanceStatus: null,
  );
}
