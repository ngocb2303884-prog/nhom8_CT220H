import 'package:flutter/foundation.dart';
import '../models/grade.dart';
import '../database/db_helper.dart';

class GradeProvider with ChangeNotifier {
  final Map<int, List<Grade>> _cache = {};

  List<Grade> gradesFor(int subjectId) => _cache[subjectId] ?? [];


  double finalScoreFor(int subjectId) {
    final grades = gradesFor(subjectId);
    if (grades.isEmpty) return 0.0;

    final totalWeight = grades.fold(0.0, (sum, g) => sum + g.weight);
    if (totalWeight == 0) return 0.0;

    final weightedSum = grades.fold(0.0, (sum, g) => sum + g.weightedScore);
    return weightedSum / totalWeight;
  }

  /// Xep loai theo thang diem 10
  String letterFor(int subjectId) {
    final s = finalScoreFor(subjectId);
    if (s >= 8.5) return 'A';
    if (s >= 8.0) return 'B+';
    if (s >= 7.0) return 'B';
    if (s >= 6.5) return 'C+';
    if (s >= 5.5) return 'C';
    if (s >= 5.0) return 'D+';
    if (s >= 4.0) return 'D';
    return 'F';
  }
  double gpa4For(int subjectId) {
    final s = finalScoreFor(subjectId);
    if (s >= 8.5) return 4.0;
    if (s >= 8.0) return 3.5;
    if (s >= 7.0) return 3.0;
    if (s >= 6.5) return 2.5;
    if (s >= 5.5) return 2.0;
    if (s >= 5.0) return 1.5;
    if (s >= 4.0) return 1.0;
    return 0.0;
  }

  Future<void> loadGrades(int subjectId) async {
    _cache[subjectId] = await DBHelper.instance.getGradesForSubject(subjectId);
    notifyListeners();
  }

  Future<void> loadGrade(int subjectId) async {
    _cache[subjectId] = await DBHelper.instance.getGradesForSubject(subjectId);
    notifyListeners();
  }

  Future<void> addGrade(Grade grade) async {
    await DBHelper.instance.insertGrade(grade);
    await loadGrades(grade.subjectId);
  }

  /*Future<void> updateGrade(Grade grade) async {
    await DBHelper.instance.updateGrade(grade);
    await loadGrades(grade.subjectId);
  }
*/
  Future<void> deleteGrade(int id, int subjectId) async {
    await DBHelper.instance.deleteGrade(id);
    await loadGrades(subjectId);
  }
}