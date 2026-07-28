class Schedule {
  final int? id;
  final int subjectId;
  final int dayOfWeek;   // 2=thu 2 ... 8=CN
  final int startPeriod; // tiet 1-12
  final int endPeriod;

  const Schedule({
    this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
  });

  static String dayName(int day) {
    const days = {
      2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4',
      5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7', 8: 'CN',
    };
    return days[day] ?? '';
  }

  static String periodTime(int period) {
    const times = {
      1: '07:00', 2: '07:50', 3: '08:50', 4: '09:50',
      5: '10:40', 6: '13:30', 7: '14:20', 8: '15:20',
      9: '16:10', 10: '', 11: '18:20', 12: '19:10',
    };
    return times[period] ?? '';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject_id': subjectId,
    'day_of_week': dayOfWeek,
    'start_period': startPeriod,
    'end_period': endPeriod,
  };

  factory Schedule.fromMap(Map<String, dynamic> m) => Schedule(
    id: m['id'] as int?,
    subjectId: m['subject_id'] as int,
    dayOfWeek: m['day_of_week'] as int,
    startPeriod: m['start_period'] as int,
    endPeriod: m['end_period'] as int,
  );
}