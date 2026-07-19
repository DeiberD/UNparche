import 'package:flutter/material.dart';

import 'services/event_api_client.dart';
import 'models/create_event_request.dart';
import 'flutter_chat/chat_socket_client.dart';
import 'location_picker_screen.dart';

/// Event creation screen.
///
/// Collects the event information, validates the publication rules, lets the
/// organizer choose a point on the campus map and sends the request to the API.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.organizerId,
    this.eventApiClient,
  });

  // Optional dependency injection keeps the screen testable without a real API.
  final EventApiClient? eventApiClient;
  final int organizerId;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Colors consistent with the rest of the application.
  static const _background = Color(0xFFFBF5F2);
  static const _surface = Color(0xFFF3ECE8);
  static const _ink = Color(0xFF263020);

  static const _eventTypes = [
    'Academico',
    'Cultural',
    'Deportivo',
    'Social',
    'Otro',
  ];
  static const _visibilityOptions = ['Publica', 'Solo grupo', 'Solo amigos'];

  // Maps user-facing labels to the identifiers expected by the backend.
  static const _eventTypeIds = {
    'Academico': 1,
    'Cultural': 2,
    'Deportivo': 3,
    'Social': 4,
    'Otro': 5,
  };
  static const _visibilityApiValues = {
    'Publica': 'PUBLICA',
    'Solo grupo': 'SOLO_GRUPO',
    'Solo amigos': 'SOLO_AMIGOS',
  };

  // Controllers own the editable text until the form is submitted or closed.
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedType = _eventTypes.first;
  String _selectedVisibility = _visibilityOptions.first;
  LocationSelection? _selectedLocation;
  bool _chatEnabled = true;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    // HU-27 only allows events to be announced up to seven days ahead.
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  DateTime? get _selectedDateTime {
    // Date and time are selected independently in the UI but sent as one value.
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String get _dateLabel {
    final date = _selectedDate;
    if (date == null) {
      return 'Seleccionar fecha';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get _timeLabel {
    final time = _selectedTime;
    if (time == null) {
      return 'Seleccionar hora';
    }

    return time.format(context);
  }

  Future<void> _pickLocation() async {
    // The picker returns both the display label and the coordinates for the API.
    final location = await Navigator.of(context).push<LocationSelection>(
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (location == null) {
      return;
    }

    setState(() {
      _selectedLocation = location;
      _locationController.text = location.label;
    });
  }

  Future<void> _publishEvent() async {
    // Prevent duplicate requests while the first publication is in progress.
    if (_isPublishing) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    final start = _selectedDateTime;
    final location = _selectedLocation;

    if (start == null) {
      _showMessage('Selecciona fecha y hora de inicio.');
      return;
    }

    if (start.isBefore(DateTime.now())) {
      _showMessage('La fecha de inicio debe ser futura.');
      return;
    }

    if (start.isAfter(DateTime.now().add(const Duration(days: 7)))) {
      _showMessage('Solo puedes publicar eventos hasta 7 dias antes.');
      return;
    }

    if (location == null) {
      _showMessage('Selecciona la ubicacion en el mapa.');
      return;
    }

    if (!isValid) {
      return;
    }

    final duration = int.parse(_durationController.text.trim());
    final end = start.add(Duration(minutes: duration));

    // HU-36 removes the event from active views 24 hours after it finishes.
    final deletionDate = end.add(const Duration(hours: 24));
    final eventTypeId = _eventTypeIds[_selectedType]!;
    final visibility = _visibilityApiValues[_selectedVisibility]!;

    setState(() => _isPublishing = true);

    try {
      final apiClient = widget.eventApiClient ?? EventApiClient();

      // Builder keeps construction readable and rejects incomplete requests.
      final request =
          (CreateEventRequestBuilder()
                ..withTitle(_titleController.text.trim())
                ..withDescription(_descriptionController.text.trim())
                ..startingAt(start)
                ..lastingMinutes(duration)
                ..atLocation(
                  latitude: location.latitude,
                  longitude: location.longitude,
                )
                ..visibleAs(visibility)
                ..organizedBy(widget.organizerId)
                ..typedAs(eventTypeId)
                ..withChatEnabled(_chatEnabled))
              .build();
      final response = await apiClient.createEvent(request);

      if (!mounted) {
        return;
      }

      final createdEvent = response['evento'];
      final eventId = createdEvent is Map<String, dynamic>
          ? createdEvent['id_evento'] as int?
          : null;

      if (_chatEnabled && eventId != null) {
        try {
          await ChatSocketClient.announceNewEvent(idEvento: eventId);
        } on ChatSocketException catch (error) {
          debugPrint(
            '[Chat] No se pudo crear sala para evento $eventId: $error',
          );
        }
      }

      if (!mounted) {
        return;
      }

      // Return the published event so the home screen can display it immediately.
      Navigator.of(context).pop(
        CreatedEventDraft(
          id: eventId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          start: start,
          durationMinutes: duration,
          end: end,
          deletionDate: deletionDate,
          locationLabel: _locationController.text.trim(),
          latitude: location.latitude,
          longitude: location.longitude,
          eventTypeId: eventTypeId,
          type: _selectedType,
          visibility: _selectedVisibility,
          chatEnabled: _chatEnabled,
        ),
      );
    } on EventApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No se pudo conectar con la API. Revisa que el backend este corriendo.',
      );
    } finally {
      // Restore the button even when validation by the API fails.
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        title: const Text(
          'Nuevo evento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              // Event identity and description.
              _CoverPhotoPlaceholder(ink: _ink, surface: _surface),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titulo del evento',
                  hintText: 'Ej. Maraton interna UNAL',
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El titulo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  hintText: 'Cuenta de que trata el evento',
                ),
                maxLength: 255,
                minLines: 4,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripcion es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Schedule fields.
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.calendar_today,
                      label: _dateLabel,
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.schedule,
                      label: _timeLabel,
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duracion en minutos',
                  hintText: 'Ej. 60',
                ),
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration <= 0) {
                    return 'Ingresa una duracion valida.';
                  }
                  if (duration > 1440) {
                    return 'La duracion maxima inicial es de 24 horas.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campus location selected through Mapbox.
              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: _pickLocation,
                decoration: const InputDecoration(
                  labelText: 'Ubicacion',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  suffixIcon: Icon(Icons.map_outlined),
                  hintText: 'Toca para marcar el punto en el mapa',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Marca la ubicacion en el mapa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              // Classification used by filters and map marker colors.
              const _SectionLabel('Tipo de evento'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    selectedColor: _ink,
                    labelStyle: TextStyle(
                      color: _selectedType == type ? Colors.white : _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              // Audience and optional event chat.
              const _SectionLabel('Visibilidad'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _visibilityOptions.map((visibility) {
                  return ChoiceChip(
                    label: Text(visibility),
                    selected: _selectedVisibility == visibility,
                    selectedColor: _ink,
                    labelStyle: TextStyle(
                      color: _selectedVisibility == visibility
                          ? Colors.white
                          : _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedVisibility = visibility);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _visibilityDescription(_selectedVisibility),
                style: TextStyle(color: _ink.withAlpha(180)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _chatEnabled,
                activeThumbColor: _ink,
                title: const Text('Chat del evento'),
                subtitle: const Text('Crear chat dedicado para asistentes'),
                onChanged: (value) => setState(() => _chatEnabled = value),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isPublishing ? null : _publishEvent,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _isPublishing ? 'Publicando...' : 'Publicar evento',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
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
      ),
    );
  }

  String _visibilityDescription(String visibility) {
    return switch (visibility) {
      'Publica' => 'Todos los usuarios autenticados pueden verlo',
      'Solo grupo' => 'Solo miembros del grupo asociado pueden verlo',
      'Solo amigos' => 'Solo tus amigos pueden verlo',
      _ => '',
    };
  }
}

/// Local representation returned to the previous screen after publication.
///
/// It avoids a second API request while the event list is being refreshed.
class CreatedEventDraft {
  const CreatedEventDraft({
    this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.durationMinutes,
    required this.end,
    required this.deletionDate,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.eventTypeId,
    required this.type,
    required this.visibility,
    required this.chatEnabled,
  });

  final int? id;
  final String title;
  final String description;
  final DateTime start;
  final int durationMinutes;
  final DateTime end;
  final DateTime deletionDate;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final int eventTypeId;
  final String type;
  final String visibility;
  final bool chatEnabled;

  String get apiVisibility {
    return switch (visibility) {
      'Publica' => 'PUBLICA',
      'Solo grupo' => 'SOLO_GRUPO',
      'Solo amigos' => 'SOLO_AMIGOS',
      _ => 'PUBLICA',
    };
  }
}

/// Placeholder for the future event cover upload control.
class _CoverPhotoPlaceholder extends StatelessWidget {
  const _CoverPhotoPlaceholder({required this.ink, required this.surface});

  final Color ink;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withAlpha(35)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: ink),
            const SizedBox(height: 8),
            Text(
              'Agregar portada',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable button for date and time selection.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: _CreateEventScreenState._ink,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}

/// Consistent heading for option groups inside the form.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _CreateEventScreenState._ink,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
  }
}
