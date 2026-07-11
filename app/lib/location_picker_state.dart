/// Coordinates and display label returned by the location picker.
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

/// State-pattern contract for the location selection workflow.
///
/// Each concrete state owns the message shown to the user, whether the current
/// selection can be confirmed and how it reacts when Mapbox becomes available.
sealed class LocationPickerState {
  const LocationPickerState();

  LocationSelection? get selection;
  String get message;
  bool get hasError;

  bool get canConfirm => selection != null;

  LocationPickerState onMapReady();

  LocationPickerState onLocationSelected(LocationSelection value) {
    return LocationSelectedState(value);
  }

  LocationPickerState onMapFailure(String errorMessage) {
    return LocationPickerErrorState(
      message: errorMessage,
      previousSelection: selection,
    );
  }
}

/// Initial state while the user has not selected a campus point.
final class AwaitingLocationState extends LocationPickerState {
  const AwaitingLocationState();

  @override
  LocationSelection? get selection => null;

  @override
  String get message => 'Toca el mapa para fijar la ubicacion.';

  @override
  bool get hasError => false;

  @override
  LocationPickerState onMapReady() => this;
}

/// State reached after a valid point has been selected.
final class LocationSelectedState extends LocationPickerState {
  const LocationSelectedState(this.value);

  final LocationSelection value;

  @override
  LocationSelection get selection => value;

  @override
  String get message => value.label;

  @override
  bool get hasError => false;

  @override
  LocationPickerState onMapReady() => this;
}

/// Temporary error state used when Mapbox cannot load correctly.
///
/// A previous selection is preserved so the user does not lose their work.
final class LocationPickerErrorState extends LocationPickerState {
  const LocationPickerErrorState({
    required this.message,
    this.previousSelection,
  });

  @override
  final String message;

  final LocationSelection? previousSelection;

  @override
  LocationSelection? get selection => previousSelection;

  @override
  bool get hasError => true;

  @override
  LocationPickerState onMapReady() {
    final selected = previousSelection;
    return selected == null
        ? const AwaitingLocationState()
        : LocationSelectedState(selected);
  }
}
