import 'package:flutter/material.dart';
import '../../models/event_summary.dart';
import '../../theme/campus_colors.dart';

String formatEventStart(DateTime? start) {
  if (start == null) {
    return 'Fecha por confirmar';
  }

  final localStart = start.toLocal();
  final hour = localStart.hour.toString().padLeft(2, '0');
  final minute = localStart.minute.toString().padLeft(2, '0');
  return '${shortEventDate(localStart)}/${localStart.year} · $hour:$minute';
}

String formatEventDate(DateTime? start) {
  if (start == null) {
    return 'Fecha no disponible';
  }

  final localStart = start.toLocal();
  return '${shortEventDate(localStart)}/${localStart.year}';
}

String formatEventTime(DateTime? start) {
  if (start == null) {
    return 'Hora no disponible';
  }

  final localStart = start.toLocal();
  final hour = localStart.hour.toString().padLeft(2, '0');
  final minute = localStart.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String groupSubtitle(EventSummary event) {
  final parts = [
    titleCaseOrFallback(event.groupCategory, 'Categoria no disponible'),
    event.groupIsOfficial == true ? 'Oficial' : 'No oficial',
  ];
  return parts.join(' · ');
}

String userSubtitle(EventSummary event) {
  return event.organizerCareer ?? event.organizerEmail ?? 'Usuario comunitario';
}

String titleCaseOrFallback(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }

  final lower = text.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String calendarTitle(DateTime date) {
  return '${monthLabel(date.month)} ${date.year}';
}

String monthLabel(int month) {
  return switch (month) {
    1 => 'Enero',
    2 => 'Febrero',
    3 => 'Marzo',
    4 => 'Abril',
    5 => 'Mayo',
    6 => 'Junio',
    7 => 'Julio',
    8 => 'Agosto',
    9 => 'Septiembre',
    10 => 'Octubre',
    11 => 'Noviembre',
    12 => 'Diciembre',
    _ => '',
  };
}

String weekdayLabel(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Lun',
    DateTime.tuesday => 'Mar',
    DateTime.wednesday => 'Mie',
    DateTime.thursday => 'Jue',
    DateTime.friday => 'Vie',
    DateTime.saturday => 'Sab',
    DateTime.sunday => 'Dom',
    _ => '',
  };
}

String shortEventDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

IconData eventIcon(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => Icons.school_outlined,
    2 => Icons.palette_outlined,
    3 => Icons.sports_soccer_outlined,
    4 => Icons.celebration_outlined,
    5 => Icons.more_horiz,
    _ => Icons.event_outlined,
  };
}

Color eventColor(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => const Color(0xFF4267B2),
    2 => const Color(0xFF8B4C9D),
    3 => const Color(0xFF2E7D32),
    4 => const Color(0xFFC2410C),
    5 => campusInk,
    _ => campusInk,
  };
}

String eventTypeLabel(int? eventTypeId) {
  return switch (eventTypeId) {
    1 => 'Academico',
    2 => 'Cultural',
    3 => 'Deportivo',
    4 => 'Social',
    5 => 'Otro',
    _ => 'Categoria',
  };
}
