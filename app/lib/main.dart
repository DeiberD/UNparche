import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'create_event_screen.dart';
import 'event_api_client.dart';
import 'view_events_screen.dart';
import 'view_groups_screen.dart';

const _mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');

enum _HomeTab { map, events, groups }

class EventFilters {
  const EventFilters({this.date, this.eventTypeId, this.groupId});

  final DateTime? date;
  final int? eventTypeId;
  final int? groupId;

  bool get hasActiveFilters =>
      date != null || eventTypeId != null || groupId != null;

  EventFilters copyWith({
    DateTime? date,
    int? eventTypeId,
    int? groupId,
    bool clearDate = false,
    bool clearEventType = false,
    bool clearGroup = false,
  }) {
    return EventFilters(
      date: clearDate ? null : date ?? this.date,
      eventTypeId: clearEventType ? null : eventTypeId ?? this.eventTypeId,
      groupId: clearGroup ? null : groupId ?? this.groupId,
    );
  }
}

String _eventTypeLabel(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => 'Academico',
    2 => 'Cultural',
    3 => 'Deportivo',
    4 => 'Social',
    5 => 'Otro',
    _ => 'Categoria',
  };
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

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

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);
  static const _accent = Color(0xFFEEDDF0);

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final _eventApiClient = EventApiClient();
  List<EventSummary> _allEvents = [];
  _HomeTab _selectedTab = _HomeTab.map;
  EventFilters _filters = const EventFilters();
  EventTimeScope _eventTimeScope = EventTimeScope.future;
  EventSummary? _focusedEvent;
  bool _isLoadingEvents = false;
  String? _eventsError;

  @override
  void initState() {
    super.initState();
    _loadVisibleEvents();
  }

  Future<void> _loadVisibleEvents() async {
    if (_isLoadingEvents) {
      return;
    }

    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final events = await _eventApiClient.fetchEvents();
      final sortedEvents = [...events]
        ..sort((a, b) {
          final aStart = a.start;
          final bStart = b.start;
          if (aStart == null && bStart == null) {
            return a.title.compareTo(b.title);
          }
          if (aStart == null) {
            return 1;
          }
          if (bStart == null) {
            return -1;
          }
          return aStart.compareTo(bStart);
        });

      if (!mounted) {
        return;
      }

      setState(() => _allEvents = sortedEvents);
    } on EventApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _eventsError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _eventsError = 'No se pudieron cargar los eventos.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _openCreateEvent(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final event = await Navigator.of(context).push<CreatedEventDraft>(
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );

    if (event == null) {
      return;
    }

    final eventSummary = EventSummary(
      id: event.id,
      title: event.title,
      description: event.description,
      start: event.start,
      durationMinutes: event.durationMinutes,
      end: event.end,
      latitude: event.latitude,
      longitude: event.longitude,
      visibility: event.apiVisibility,
      organizerId: 1,
      organizerName: 'Usuario comunitario',
      organizerEmail: null,
      organizerCareer: null,
      organizerInfo: null,
      groupId: null,
      groupName: null,
      groupDescription: null,
      groupCategory: null,
      groupIsOfficial: null,
      groupVerificationStatus: null,
      eventTypeId: event.eventTypeId,
      eventTypeName: null,
      status: 'PROGRAMADO',
      chatEnabled: event.chatEnabled,
    );
    setState(() {
      _allEvents = [..._allEvents, eventSummary]
        ..sort(
          (a, b) =>
              (a.start ?? DateTime(9999)).compareTo(b.start ?? DateTime(9999)),
        );
      _focusedEvent = eventSummary;
    });
    _loadVisibleEvents();

    messenger.showSnackBar(
      SnackBar(content: Text('Evento "${event.title}" publicado.')),
    );
  }

  List<EventSummary> get _filteredEvents {
    return _eventsMatchingFilters(includeDate: true);
  }

  List<EventSummary> get _eventsForCalendar {
    return _eventsMatchingFilters(includeDate: false);
  }

  List<EventSummary> _eventsMatchingFilters({required bool includeDate}) {
    final now = DateTime.now();
    return _allEvents.where((event) {
      if (!_matchesTimeScope(event, now)) {
        return false;
      }

      final date = _filters.date;
      if (includeDate && date != null) {
        final start = event.start;
        if (start == null || !DateUtils.isSameDay(start.toLocal(), date)) {
          return false;
        }
      }

      final eventTypeId = _filters.eventTypeId;
      if (eventTypeId != null && event.eventTypeId != eventTypeId) {
        return false;
      }

      final groupId = _filters.groupId;
      if (groupId != null && event.groupId != groupId) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _matchesTimeScope(EventSummary event, DateTime now) {
    final eventStart = event.start;
    if (!event.isPublic || eventStart == null) {
      return false;
    }

    final eventDate = DateUtils.dateOnly(eventStart.toLocal());
    final today = DateUtils.dateOnly(now);
    final next7Days = DateUtils.dateOnly(now.add(const Duration(days: 7)));

    return switch (_eventTimeScope) {
      EventTimeScope.future =>
        event.isActive &&
            !eventDate.isBefore(today) &&
            !eventDate.isAfter(next7Days),
      EventTimeScope.past =>
        event.status != 'CANCELADO' && eventDate.isBefore(today),
    };
  }

  List<int> get _availableGroupIds {
    final groupIds =
        _allEvents
            .map((event) => event.groupId)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return groupIds;
  }

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final firstDate = _eventTimeScope == EventTimeScope.past
        ? DateTime(now.year - 5)
        : DateTime(now.year, now.month, now.day);
    final lastDate = _eventTimeScope == EventTimeScope.past
        ? DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 1))
        : DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
    final selectedDate = _filters.date;
    final defaultDate = _eventTimeScope == EventTimeScope.past
        ? lastDate
        : firstDate;
    final initialDate =
        selectedDate != null &&
            !selectedDate.isBefore(firstDate) &&
            !selectedDate.isAfter(lastDate)
        ? selectedDate
        : defaultDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() => _filters = _filters.copyWith(date: picked));
    }
  }

  Future<void> _pickEventTypeFilter() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: CampusMapScreen._background,
      builder: (_) => const _EventTypeFilterSheet(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filters = selected == null
          ? _filters.copyWith(clearEventType: true)
          : _filters.copyWith(eventTypeId: selected);
    });
  }

  Future<void> _pickGroupFilter() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: CampusMapScreen._background,
      builder: (_) => _GroupFilterSheet(groupIds: _availableGroupIds),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filters = selected == null
          ? _filters.copyWith(clearGroup: true)
          : _filters.copyWith(groupId: selected);
    });
  }

  void _clearFilters() {
    setState(() => _filters = const EventFilters());
  }

  Future<void> _openEventDetails(EventSummary event) async {
    final shouldOpenLocation = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );

    if (shouldOpenLocation == true && mounted) {
      setState(() {
        _selectedTab = _HomeTab.map;
        _focusedEvent = event;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filteredEvents;
    final showEventControls = _selectedTab != _HomeTab.groups;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: switch (_selectedTab) {
                _HomeTab.map =>
                  _mapboxAccessToken.isEmpty
                      ? const MissingMapboxTokenView()
                      : UNALMap(
                          events: filteredEvents,
                          focusedEvent: _focusedEvent,
                          onEventTap: _openEventDetails,
                        ),
                _HomeTab.events => EventsListView(
                  events: filteredEvents,
                  calendarEvents: _eventsForCalendar,
                  selectedDate: _filters.date,
                  timeScope: _eventTimeScope,
                  isLoading: _isLoadingEvents,
                  errorMessage: _eventsError,
                  onRefresh: _loadVisibleEvents,
                  onEventTap: _openEventDetails,
                  onDateSelected: (date) {
                    setState(() {
                      _filters = date == null
                          ? _filters.copyWith(clearDate: true)
                          : _filters.copyWith(date: date);
                    });
                  },
                  onTimeScopeChanged: (scope) {
                    setState(() {
                      _eventTimeScope = scope;
                      _filters = _filters.copyWith(clearDate: true);
                    });
                  },
                ),
                _HomeTab.groups => const GroupsScreen(),
              },
            ),
            const Positioned(left: 16, right: 16, top: 14, child: MapHeader()),
            if (showEventControls)
              Positioned(
                left: 16,
                right: 16,
                top: 82,
                child: EventFiltersBar(
                  filters: _filters,
                  onDatePressed: _pickDateFilter,
                  onTypePressed: _pickEventTypeFilter,
                  onGroupPressed: _pickGroupFilter,
                  onClearPressed: _filters.hasActiveFilters
                      ? _clearFilters
                      : null,
                ),
              ),
            if (showEventControls && (_isLoadingEvents || _eventsError != null))
              Positioned(
                left: 18,
                right: 18,
                top: 134,
                child: MapStatusMessage(
                  message: _eventsError ?? 'Cargando eventos...',
                  hasError: _eventsError != null,
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _BottomNavigationMock(
                selectedTab: _selectedTab,
                onTabSelected: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
            if (showEventControls)
              Positioned(
                right: 18,
                bottom: 104,
                child: FloatingActionButton(
                  heroTag: 'createEvent',
                  tooltip: 'Crear evento',
                  backgroundColor: CampusMapScreen._ink,
                  foregroundColor: Colors.white,
                  onPressed: () => _openCreateEvent(context),
                  child: const Icon(Icons.add),
                ),
              ),
            if (_selectedTab == _HomeTab.map)
              Positioned(
                right: 18,
                bottom: 170,
                child: FloatingActionButton.small(
                  heroTag: 'refreshEvents',
                  tooltip: 'Actualizar eventos',
                  backgroundColor: CampusMapScreen._surface,
                  foregroundColor: CampusMapScreen._ink,
                  onPressed: _loadVisibleEvents,
                  child: const Icon(Icons.refresh),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UNALMap extends StatefulWidget {
  const UNALMap({
    super.key,
    required this.events,
    required this.onEventTap,
    this.focusedEvent,
  });

  final List<EventSummary> events;
  final ValueChanged<EventSummary> onEventTap;
  final EventSummary? focusedEvent;

  @override
  State<UNALMap> createState() => _UNALMapState();
}

class _UNALMapState extends State<UNALMap> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _eventMarkerManager;
  final Map<String, EventSummary> _eventsByAnnotationId = {};
  dynamic _eventMarkerTapSubscription;
  String? _statusMessage = 'Cargando mapa...';
  bool _hasError = false;

  static final _campusBounds = CoordinateBounds(
    // Approximate UNAL Bogota campus box. We can tighten it later with exact GIS data.
    southwest: Point(coordinates: Position(-74.0985, 4.6255)),
    northeast: Point(coordinates: Position(-74.0725, 4.6505)),
    infiniteBounds: false,
  );

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: _campusBounds,
        minZoom: 14.0,
        maxZoom: 25,
        minPitch: 0,
        maxPitch: 45,
      ),
    );

    _eventMarkerManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    _eventMarkerTapSubscription = _eventMarkerManager?.tapEvents(
      onTap: _handleMarkerTap,
    );
    await _syncEventMarkers();
  }

  @override
  void dispose() {
    _eventMarkerTapSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UNALMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.events != widget.events ||
        oldWidget.focusedEvent?.id != widget.focusedEvent?.id) {
      _syncEventMarkers();
    }
  }

  Future<void> _syncEventMarkers() async {
    final manager = _eventMarkerManager;
    if (manager == null) {
      return;
    }

    await manager.deleteAll();
    _eventsByAnnotationId.clear();
    for (final event in widget.events) {
      final latitude = event.latitude;
      final longitude = event.longitude;
      if (latitude == null || longitude == null) {
        continue;
      }

      final annotation = await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(longitude, latitude)),
          circleRadius: 8,
          circleColor: _eventColor(event.eventTypeId).toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3,
        ),
      );
      _eventsByAnnotationId[annotation.id] = event;
    }

    final latest = widget.focusedEvent ?? widget.events.lastOrNull;
    if (latest != null && latest.latitude != null && latest.longitude != null) {
      await _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(latest.longitude!, latest.latitude!),
          ),
          zoom: 16.5,
        ),
      );
    }
  }

  void _handleMarkerTap(CircleAnnotation annotation) {
    final event = _eventsByAnnotationId[annotation.id];
    if (event != null) {
      widget.onEventTap(event);
    }
  }

  Color _eventColor(int? eventTypeId) {
    return switch (eventTypeId) {
      1 => const Color(0xFF4267B2),
      2 => const Color(0xFF8B4C9D),
      3 => const Color(0xFF2E7D32),
      4 => const Color(0xFFC2410C),
      5 => CampusMapScreen._ink,
      _ => CampusMapScreen._ink,
    };
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
          onMapCreated: _onMapCreated,
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

class _EventTypeFilterSheet extends StatelessWidget {
  const _EventTypeFilterSheet();

  static const _types = [
    (id: 1, label: 'Academico', icon: Icons.school_outlined),
    (id: 2, label: 'Cultural', icon: Icons.palette_outlined),
    (id: 3, label: 'Deportivo', icon: Icons.sports_soccer_outlined),
    (id: 4, label: 'Social', icon: Icons.celebration_outlined),
    (id: 5, label: 'Otro', icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por categoria',
              style: TextStyle(
                color: CampusMapScreen._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _FilterSheetOption(
              icon: Icons.clear,
              label: 'Todas las categorias',
              onTap: () => Navigator.of(context).pop(null),
            ),
            ..._types.map(
              (type) => _FilterSheetOption(
                icon: type.icon,
                label: type.label,
                onTap: () => Navigator.of(context).pop(type.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupFilterSheet extends StatelessWidget {
  const _GroupFilterSheet({required this.groupIds});

  final List<int> groupIds;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por grupo',
              style: TextStyle(
                color: CampusMapScreen._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _FilterSheetOption(
              icon: Icons.clear,
              label: 'Todos los grupos',
              onTap: () => Navigator.of(context).pop(null),
            ),
            if (groupIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No hay grupos disponibles en los eventos actuales.',
                  style: TextStyle(
                    color: CampusMapScreen._ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...groupIds.map(
                (groupId) => _FilterSheetOption(
                  icon: Icons.groups_outlined,
                  label: 'Grupo $groupId',
                  onTap: () => Navigator.of(context).pop(groupId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetOption extends StatelessWidget {
  const _FilterSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: CampusMapScreen._ink),
      title: Text(
        label,
        style: const TextStyle(
          color: CampusMapScreen._ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class EventFiltersBar extends StatelessWidget {
  const EventFiltersBar({
    super.key,
    required this.filters,
    required this.onDatePressed,
    required this.onTypePressed,
    required this.onGroupPressed,
    required this.onClearPressed,
  });

  final EventFilters filters;
  final VoidCallback onDatePressed;
  final VoidCallback onTypePressed;
  final VoidCallback onGroupPressed;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChipMock(
            icon: Icons.tune,
            label: filters.eventTypeId == null
                ? 'Categoria'
                : _eventTypeLabel(filters.eventTypeId),
            selected: filters.eventTypeId != null,
            onPressed: onTypePressed,
          ),
          const SizedBox(width: 8),
          FilterChipMock(
            icon: Icons.calendar_today,
            label: filters.date == null ? 'Fecha' : _shortDate(filters.date!),
            selected: filters.date != null,
            onPressed: onDatePressed,
          ),
          const SizedBox(width: 8),
          FilterChipMock(
            icon: Icons.group,
            label: filters.groupId == null
                ? 'Grupo'
                : 'Grupo ${filters.groupId}',
            selected: filters.groupId != null,
            onPressed: onGroupPressed,
          ),
          if (onClearPressed != null) ...[
            const SizedBox(width: 8),
            FilterChipMock(
              icon: Icons.close,
              label: 'Limpiar',
              selected: true,
              onPressed: onClearPressed!,
            ),
          ],
        ],
      ),
    );
  }
}

class FilterChipMock extends StatelessWidget {
  const FilterChipMock({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CampusMapScreen._ink : Colors.white.withAlpha(238),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? CampusMapScreen._ink
                  : CampusMapScreen._ink.withAlpha(24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : CampusMapScreen._ink,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : CampusMapScreen._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationMock extends StatelessWidget {
  const _BottomNavigationMock({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onTabSelected;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.map_outlined,
            label: 'Mapa',
            selected: selectedTab == _HomeTab.map,
            onPressed: () => onTabSelected(_HomeTab.map),
          ),
          BottomNavItem(
            icon: Icons.event_outlined,
            label: 'Eventos',
            selected: selectedTab == _HomeTab.events,
            onPressed: () => onTabSelected(_HomeTab.events),
          ),
          BottomNavItem(
            icon: Icons.groups_outlined,
            label: 'Grupos',
            selected: selectedTab == _HomeTab.groups,
            onPressed: () => onTabSelected(_HomeTab.groups),
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            label: 'Amigos',
            onPressed: () {},
          ),
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
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CampusMapScreen._ink
        : CampusMapScreen._ink.withAlpha(170);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
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
      ),
    );
  }
}
