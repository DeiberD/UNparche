import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

class LocationSelection {
  const LocationSelection({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final LocationSelection? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);
  static const _campusLatitude = 4.6382;
  static const _campusLongitude = -74.0840;

  static final _campusBounds = CoordinateBounds(
    southwest: Point(coordinates: Position(-74.0985, 4.6255)),
    northeast: Point(coordinates: Position(-74.0725, 4.6505)),
    infiniteBounds: false,
  );

  CircleAnnotationManager? _circleManager;
  CircleAnnotation? _selectedMarker;
  LocationSelection? _selectedLocation;
  String? _statusMessage = 'Toca el mapa para fijar la ubicacion.';
  bool _hasMapError = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
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
      TapInteraction.onMap(_onMapTap),
      interactionID: 'location-picker-tap',
    );
    final selected = _selectedLocation;
    if (selected != null) {
      await _setSelectedLocation(selected.latitude, selected.longitude);
    }
  }

  Future<void> _setSelectedLocation(double latitude, double longitude) async {
    final selection = LocationSelection(
      latitude: latitude,
      longitude: longitude,
      label: _formatLocationLabel(latitude, longitude),
    );

    final point = Point(coordinates: Position(longitude, latitude));
    final manager = _circleManager;

    if (manager != null) {
      final marker = _selectedMarker;
      if (marker == null) {
        _selectedMarker = await manager.create(
          CircleAnnotationOptions(
            geometry: point,
            circleRadius: 9,
            circleColor: _ink.toARGB32(),
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 3,
          ),
        );
      } else {
        marker.geometry = point;
        await manager.update(marker);
      }
    }

    setState(() {
      _selectedLocation = selection;
      _statusMessage = selection.label;
      _hasMapError = false;
    });
  }

  void _onMapTap(MapContentGestureContext context) {
    final coordinates = context.point.coordinates;
    _setSelectedLocation(
      coordinates.lat.toDouble(),
      coordinates.lng.toDouble(),
    );
  }

  void _confirmSelection() {
    final selected = _selectedLocation;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un punto dentro del campus.')),
      );
      return;
    }

    Navigator.of(context).pop(selected);
  }

  static String _formatLocationLabel(double latitude, double longitude) {
    return 'Campus UNAL (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        title: const Text(
          'Ubicacion del evento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('locationPickerMap'),
                styleUri: MapboxStyles.MAPBOX_STREETS,
                viewport: CameraViewportState(
                  center: Point(
                    coordinates: Position(_campusLongitude, _campusLatitude),
                  ),
                  zoom: 16,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: (_) {
                  setState(() {
                    _statusMessage =
                        _selectedLocation?.label ??
                        'Toca el mapa para fijar la ubicacion.';
                    _hasMapError = false;
                  });
                },
                onMapLoadErrorListener: (error) {
                  setState(() {
                    _statusMessage =
                        'Mapbox: ${error.type.name} - ${error.message}';
                    _hasMapError = true;
                  });
                },
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: _MapInstructionCard(
                message: _statusMessage ?? '',
                hasError: _hasMapError,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: FilledButton.icon(
                onPressed: _confirmSelection,
                icon: const Icon(Icons.check),
                label: const Text('Usar esta ubicacion'),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapInstructionCard extends StatelessWidget {
  const _MapInstructionCard({required this.message, required this.hasError});

  final String message;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF1F1)
            : _LocationPickerScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _LocationPickerScreenState._ink.withAlpha(20),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.location_on_outlined,
              color: hasError
                  ? const Color(0xFFB3261E)
                  : _LocationPickerScreenState._ink,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: hasError
                      ? const Color(0xFFB3261E)
                      : _LocationPickerScreenState._ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
