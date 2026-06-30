import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const _mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (_mapboxAccessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(_mapboxAccessToken);
  }

  runApp(const UNparcheApp());
}

class UNparcheApp extends StatelessWidget {
  const UNparcheApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFBF5F2);
    const ink = Color(0xFF263020);

    return MaterialApp(
      title: 'UNparche',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: background),
        scaffoldBackgroundColor: background,
        useMaterial3: true,
      ),
      home: const CampusMapScreen(),
    );
  }
}

class CampusMapScreen extends StatelessWidget {
  const CampusMapScreen({super.key});

  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);
  static const _accent = Color(0xFFEEDDF0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _mapboxAccessToken.isEmpty
                  ? const MissingMapboxTokenView()
                  : const UNALMap(),
            ),
            const Positioned(left: 16, right: 16, top: 14, child: MapHeader()),
            const Positioned(left: 16, right: 16, top: 82, child: MapFilters()),
            const Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: BottomNavigationMock(),
            ),
          ],
        ),
      ),
    );
  }
}

class UNALMap extends StatefulWidget {
  const UNALMap({super.key});

  @override
  State<UNALMap> createState() => _UNALMapState();
}

class _UNALMapState extends State<UNALMap> {
  String? _statusMessage = 'Cargando mapa...';
  bool _hasError = false;

  static final _campusBounds = CoordinateBounds(
    // Approximate UNAL Bogota campus box. We can tighten it later with exact GIS data.
    southwest: Point(coordinates: Position(-74.0985, 4.6255)),
    northeast: Point(coordinates: Position(-74.0725, 4.6505)),
    infiniteBounds: false,
  );

  Future<void> _applyCampusBounds(MapboxMap mapboxMap) {
    return mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: _campusBounds,
        minZoom: 14.0,
        maxZoom: 25,
        minPitch: 0,
        maxPitch: 45,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('campusMap'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          viewport: CameraViewportState(
            center: Point(coordinates: Position(-74.0840, 4.6382)),
            zoom: 15.6,
          ),
          onMapCreated: _applyCampusBounds,
          onStyleLoadedListener: (_) {
            setState(() {
              _statusMessage = null;
              _hasError = false;
            });
          },
          onMapLoadErrorListener: (error) {
            setState(() {
              _statusMessage = 'Mapbox: ${error.type.name} - ${error.message}';
              _hasError = true;
            });
          },
        ),
        if (_statusMessage != null)
          Positioned(
            left: 18,
            right: 18,
            bottom: 104,
            child: MapStatusMessage(
              message: _statusMessage!,
              hasError: _hasError,
            ),
          ),
      ],
    );
  }
}

class MapStatusMessage extends StatelessWidget {
  const MapStatusMessage({
    super.key,
    required this.message,
    required this.hasError,
  });

  final String message;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF1F1) : Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? const Color(0xFFB3261E)
              : CampusMapScreen._ink.withAlpha(24),
        ),
        boxShadow: [
          BoxShadow(
            color: CampusMapScreen._ink.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          message,
          style: TextStyle(
            color: hasError ? const Color(0xFFB3261E) : CampusMapScreen._ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class MissingMapboxTokenView extends StatelessWidget {
  const MissingMapboxTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CampusMapScreen._background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CampusMapScreen._ink.withAlpha(24)),
          boxShadow: [
            BoxShadow(
              color: CampusMapScreen._ink.withAlpha(18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapbox necesita un token',
              style: TextStyle(
                color: CampusMapScreen._ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Para probar el mapa, ejecuta la app con tu token publico de Mapbox:',
              style: TextStyle(
                color: CampusMapScreen._ink,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            SizedBox(height: 14),
            SelectableText(
              'flutter run --dart-define ACCESS_TOKEN=tu_token',
              style: TextStyle(
                color: CampusMapScreen._ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapHeader extends StatelessWidget {
  const MapHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: CampusMapScreen._surface.withAlpha(242),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CampusMapScreen._ink.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 17,
            backgroundColor: CampusMapScreen._accent,
            child: Icon(Icons.person, color: CampusMapScreen._ink, size: 20),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'UNparche',
                style: TextStyle(
                  color: CampusMapScreen._ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            color: CampusMapScreen._ink,
            tooltip: 'Buscar',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class MapFilters extends StatelessWidget {
  const MapFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        FilterChipMock(icon: Icons.tune, label: 'Categoria'),
        SizedBox(width: 8),
        FilterChipMock(icon: Icons.calendar_today, label: 'Fecha'),
        SizedBox(width: 8),
        FilterChipMock(icon: Icons.group, label: 'Amigos'),
      ],
    );
  }
}

class FilterChipMock extends StatelessWidget {
  const FilterChipMock({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CampusMapScreen._ink.withAlpha(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: CampusMapScreen._ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: CampusMapScreen._ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigationMock extends StatelessWidget {
  const BottomNavigationMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: CampusMapScreen._surface.withAlpha(246),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CampusMapScreen._ink.withAlpha(20),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            selected: true,
          ),
          BottomNavItem(icon: Icons.event_outlined, label: 'Eventos'),
          BottomNavItem(icon: Icons.groups_outlined, label: 'Grupos'),
          BottomNavItem(icon: Icons.person_outline, label: 'Amigos'),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CampusMapScreen._ink
        : CampusMapScreen._ink.withAlpha(170);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: selected ? CampusMapScreen._accent : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
