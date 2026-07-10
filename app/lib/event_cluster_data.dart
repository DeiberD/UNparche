import 'event_api_client.dart';

const eventClusterSourceId = 'event-points';
const eventClustersLayerId = 'event-clusters';
const eventClusterCountLayerId = 'event-cluster-count';
const unclusteredEventsLayerId = 'unclustered-events';

const eventClusterMaxZoom = 16.0;
const eventClusterRadius = 56.0;

String eventClusterKey(EventSummary event, int index) {
  final id = event.id;
  return id == null ? 'draft-$index' : 'event-$id';
}

Map<String, dynamic> buildEventClusterFeatureCollection(
  List<EventSummary> events,
) {
  final features = <Map<String, dynamic>>[];

  for (var index = 0; index < events.length; index++) {
    final event = events[index];
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) {
      continue;
    }

    features.add({
      'type': 'Feature',
      'id': eventClusterKey(event, index),
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {
        'event_key': eventClusterKey(event, index),
        'event_type_id': event.eventTypeId ?? 0,
      },
    });
  }

  return {'type': 'FeatureCollection', 'features': features};
}
