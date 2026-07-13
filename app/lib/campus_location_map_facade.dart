import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'location_picker_state.dart';

/// Facade over the Mapbox operations required by the location picker.
///
/// The UI only initializes the campus map and asks this class to display a
/// selection. Bounds, annotations and interaction lifecycle remain hidden.
class CampusLocationMapFacade {
  CampusLocationMapFacade({required this.markerColor});

  static const _interactionId = 'location-picker-tap';
  static const _campusLatitude = 4.6382;
  static const _campusLongitude = -74.0840;

  static final _campusBounds = CoordinateBounds(
    southwest: Point(coordinates: Position(-74.0985, 4.6255)),
    northeast: Point(coordinates: Position(-74.0725, 4.6505)),
    infiniteBounds: false,
  );

  final int markerColor;

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  CircleAnnotation? _selectedMarker;

  /// Camera configuration used when the picker first opens.
  CameraViewportState get initialViewport => CameraViewportState(
    center: Point(coordinates: Position(_campusLongitude, _campusLatitude)),
    zoom: 16,
  );

  /// Configures campus limits, marker annotations and map-tap interaction.
  Future<void> initialize(
    MapboxMap mapboxMap, {
    required void Function(MapContentGestureContext context) onMapTap,
  }) async {
    _mapboxMap = mapboxMap;

    await mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: _campusBounds,
        minZoom: 14,
        maxZoom: 25,
        minPitch: 0,
        maxPitch: 45,
      ),
    );

    _circleManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    mapboxMap.addInteraction(
      TapInteraction.onMap(onMapTap),
      interactionID: _interactionId,
    );
  }

  /// Creates the marker once and moves it on subsequent selections.
  Future<void> showSelection(LocationSelection selection) async {
    final manager = _circleManager;
    if (manager == null) {
      return;
    }

    final point = Point(
      coordinates: Position(selection.longitude, selection.latitude),
    );
    final marker = _selectedMarker;
    if (marker == null) {
      _selectedMarker = await manager.create(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: 9,
          circleColor: markerColor,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
        ),
      );
      return;
    }

    marker.geometry = point;
    await manager.update(marker);
  }

  /// Removes the registered interaction when the screen is disposed.
  void dispose() {
    _mapboxMap?.removeInteraction(_interactionId);
    _mapboxMap = null;
    _circleManager = null;
    _selectedMarker = null;
  }
}
