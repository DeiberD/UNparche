import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'campus_location_map_facade.dart';
import 'location_picker_state.dart';
export 'location_picker_state.dart' show LocationSelection;

/// Mapbox screen used to choose the exact campus location of an event.
///
/// The screen acts as the context of the State pattern. It delegates the
/// workflow status, confirmation availability and transitions to
/// [LocationPickerState] implementations. Mapbox-specific operations are
/// delegated to [CampusLocationMapFacade].
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final LocationSelection? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Colors shared by the picker UI and its Mapbox facade.
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);

  late final CampusLocationMapFacade _mapFacade;
  late LocationPickerState _pickerState;

  @override
  void initState() {
    super.initState();

    _mapFacade = CampusLocationMapFacade(markerColor: _ink.toARGB32());

    // Restore an existing location when the user reopens the picker.
    final initialLocation = widget.initialLocation;
    _pickerState = initialLocation == null
        ? const AwaitingLocationState()
        : LocationSelectedState(initialLocation);
  }

  @override
  void dispose() {
    _mapFacade.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    // One facade call replaces Mapbox bounds, annotations and interaction setup.
    await _mapFacade.initialize(mapboxMap, onMapTap: _onMapTap);

    // Recreate the marker when editing a previously selected location.
    final selected = _pickerState.selection;
    if (selected != null) {
      await _setSelectedLocation(selected.latitude, selected.longitude);
    }
  }

  Future<void> _setSelectedLocation(double latitude, double longitude) async {
    // Convert the raw Mapbox coordinate into the value returned to the form.
    final selection = LocationSelection(
      latitude: latitude,
      longitude: longitude,
      label: _formatLocationLabel(latitude, longitude),
    );

    await _mapFacade.showSelection(selection);

    setState(() {
      _pickerState = _pickerState.onLocationSelected(selection);
    });
  }

  void _onMapTap(MapContentGestureContext context) {
    // Mapbox stores coordinates as longitude/latitude; the domain model uses
    // named fields to avoid accidentally swapping them.
    final coordinates = context.point.coordinates;
    _setSelectedLocation(
      coordinates.lat.toDouble(),
      coordinates.lng.toDouble(),
    );
  }

  void _confirmSelection() {
    final selected = _pickerState.selection;
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
                viewport: _mapFacade.initialViewport,
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: (_) {
                  setState(() {
                    _pickerState = _pickerState.onMapReady();
                  });
                },
                onMapLoadErrorListener: (error) {
                  setState(() {
                    _pickerState = _pickerState.onMapFailure(
                      'Mapbox: ${error.type.name} - ${error.message}',
                    );
                  });
                },
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: _MapInstructionCard(
                message: _pickerState.message,
                hasError: _pickerState.hasError,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: FilledButton.icon(
                onPressed: _pickerState.canConfirm ? _confirmSelection : null,
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

/// Status card driven by the active [LocationPickerState].
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
