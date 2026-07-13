import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/event_api_client.dart';
import 'package:app/event_cluster_data.dart';
import 'package:app/location_picker_state.dart';

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

  testWidgets('shows UNparche on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UNparcheApp());

    expect(find.text('UNparche'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('requires a session before opening event creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UNparcheApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
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
