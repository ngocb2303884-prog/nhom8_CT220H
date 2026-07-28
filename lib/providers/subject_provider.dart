import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/schedule.dart';
import '../database/db_helper.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _loading = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get loading => _loading;

  Future<void> loadSubjects() async {
    _loading = true;
    notifyListeners();

    _subjects = await DBHelper.instance.getAllSubjects();

    _loading = false;
    notifyListeners();
  }

  Future<void> addSubject(Subject subject, List<Schedule> schedules) async {
    final subjectId = await DBHelper.instance.insertSubject(subject);

    for (final s in schedules) {
      await DBHelper.instance.insertSchedule(Schedule(
        subjectId: subjectId,
        dayOfWeek: s.dayOfWeek,
        startPeriod: s.startPeriod,
        endPeriod: s.endPeriod,
      ));
    }
    await loadSubjects();
  }

  Future<void> updateSubject(Subject subject, List<Schedule> schedules) async {
    await DBHelper.instance.updateSubject(subject);

    // xoa lich cu them lich moi
    await DBHelper.instance.deleteSchedulesForSubject(subject.id!);
    for (final s in schedules) {
      await DBHelper.instance.insertSchedule(Schedule(
        subjectId: subject.id!,
        dayOfWeek: s.dayOfWeek,
        startPeriod: s.startPeriod,
        endPeriod: s.endPeriod,
      ));
    }
    await loadSubjects();
  }

  Future<void> deleteSubject(int id) async {
    await DBHelper.instance.deleteSubject(id);
    await loadSubjects();
  }

  Future<List<Schedule>> getSchedulesFor(int subjectId) async {
    return await DBHelper.instance.getSchedulesForSubject(subjectId);
  }
}