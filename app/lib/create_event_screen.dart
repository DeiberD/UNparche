import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _locationController = TextEditingController(text: 'Campus UNAL Bogota');

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedType = _eventTypes.first;
  String _selectedVisibility = _visibilityOptions.first;
  bool _chatEnabled = true;

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

  void _publishEvent() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final start = _selectedDateTime;

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

    if (!isValid) {
      return;
    }

    final duration = int.parse(_durationController.text.trim());
    final end = start.add(Duration(minutes: duration));
    final deletionDate = end.add(const Duration(hours: 24));

    Navigator.of(context).pop(
      CreatedEventDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        start: start,
        durationMinutes: duration,
        end: end,
        deletionDate: deletionDate,
        locationLabel: _locationController.text.trim(),
        type: _selectedType,
        visibility: _selectedVisibility,
        chatEnabled: _chatEnabled,
      ),
    );
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicacion',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Lugar dentro del campus',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ubicacion es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
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
                  onPressed: _publishEvent,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publicar evento'),
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

class CreatedEventDraft {
  const CreatedEventDraft({
    required this.title,
    required this.description,
    required this.start,
    required this.durationMinutes,
    required this.end,
    required this.deletionDate,
    required this.locationLabel,
    required this.type,
    required this.visibility,
    required this.chatEnabled,
  });

  final String title;
  final String description;
  final DateTime start;
  final int durationMinutes;
  final DateTime end;
  final DateTime deletionDate;
  final String locationLabel;
  final String type;
  final String visibility;
  final bool chatEnabled;
}

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
