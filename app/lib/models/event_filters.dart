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
      date: clearDate ? null : (date ?? this.date),
      eventTypeId: clearEventType ? null : (eventTypeId ?? this.eventTypeId),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
    );
  }
}
