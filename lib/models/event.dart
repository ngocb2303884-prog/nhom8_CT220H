class AcademicEvent {
  final int? id;
  final int subjectId;
  final String title;
  final String type;
  final DateTime dateTime;
  final String notes;

  AcademicEvent({
    this.id,
    required this.subjectId,
    required this.title,
    required this.type,
    required this.dateTime,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'type': type,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory AcademicEvent.fromMap(Map<String, dynamic> map) {
    return AcademicEvent(
      id: map['id'],
      subjectId: map['subject_id'],
      title: map['title'],
      type: map['type'],
      dateTime: DateTime.parse(map['date_time']),
      notes: map['notes'] ?? '',
    );
  }
}