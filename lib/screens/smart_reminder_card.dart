import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/schedule.dart';
import '../database/db_helper.dart';

// ==========================================
// WIDGET NHẮC NHỞ THÔNG MINH (AI / HEURISTIC)
// ==========================================
class SmartStudyPlanner extends StatefulWidget {
  const SmartStudyPlanner({Key? key}) : super(key: key);

  @override
  State<SmartStudyPlanner> createState() => _SmartStudyPlannerState();
}

class _SmartStudyPlannerState extends State<SmartStudyPlanner> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _generateSmartSchedule();
  }

  Future<void> _generateSmartSchedule() async {
    setState(() => _isLoading = true);

    // 1. Lấy toàn bộ dữ liệu cần thiết từ Database
    final subjects = await DBHelper.instance.getAllSubjects();
    final events = await DBHelper.instance.getAllEvents();

    // Lập bản đồ thời gian bận trong tuần (Thứ 2 -> CN)
    Map<int, List<int>> busyPeriods = {};
    for (int day = 2; day <= 8; day++) {
      busyPeriods[day] = [];
      final dailySchedules = await DBHelper.instance.getSchedulesForDay(day);
      for (var sch in dailySchedules) {
        int start = sch['start_period'];
        int end = sch['end_period'];
        for (int i = start; i <= end; i++) {
          busyPeriods[day]!.add(i);
        }
      }
    }

    // 2. TÍNH TOÁN TRỌNG SỐ ƯU TIÊN (Priority Score)
    List<Map<String, dynamic>> subjectPriorities = [];
    final now = DateTime.now();

    for (var sub in subjects) {
      int score = sub.credits * 10; // Trọng số cơ bản: Dựa trên số tín chỉ
      bool hasUpcomingExam = false;

      // Quét xem môn này có deadline/thi trong 7 ngày tới không
      for (var event in events) {
        if (event.subjectId == sub.id) {
          final eventDate = event.dateTime;
          final difference = eventDate.difference(now).inDays;
          if (difference >= 0 && difference <= 7) {
            score += 50; // Trọng số khẩn cấp
            hasUpcomingExam = true;
            break;
          }
        }
      }
      subjectPriorities.add({'subject': sub, 'score': score, 'urgent': hasUpcomingExam});
    }

    // Sắp xếp môn học theo độ ưu tiên giảm dần
    subjectPriorities.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // 3. THUẬT TOÁN TÌM KHUNG GIỜ TRỐNG (Greedy Search)
    List<Map<String, dynamic>> finalSuggestions = [];

    // Quét 3 ngày tiếp theo để lên lịch
    for (int offset = 1; offset <= 3; offset++) {
      int targetDay = now.weekday + offset;
      if (targetDay > 7) targetDay -= 7; // Quay vòng tuần
      int dayToMap = targetDay + 1; // Hệ thống map Thứ 2 = 2

      List<int> dayBusy = busyPeriods[dayToMap] ?? [];

      // ĐẾM SỐ TIẾT HỌC BUỔI SÁNG (Tiết 1 -> 5)
      int morningLoad = dayBusy.where((p) => p >= 1 && p <= 5).length;
      bool skipAfternoon = morningLoad >= 4; // QUY TẮC SỨC KHỎE

      for (var sp in subjectPriorities) {
        // Nếu môn này đã được lên lịch rồi thì bỏ qua
        if (finalSuggestions.any((s) => s['subject'].id == sp['subject'].id)) continue;

        String? suggestedTime;
        String reason = '';

        // Ưu tiên 1: Cố gắng xếp buổi sáng nếu rảnh (Tiết 1-4) cho môn khó
        if (!dayBusy.contains(1) && !dayBusy.contains(2) && !dayBusy.contains(3)) {
          suggestedTime = 'Sáng (Tiết 1-3)';
          reason = 'Môn nhiều tín chỉ, nên học lúc não bộ minh mẫn nhất.';
        }
        // Ưu tiên 2: Xếp buổi chiều nếu sáng không học quá sức
        else if (!skipAfternoon && !dayBusy.contains(6) && !dayBusy.contains(7) && !dayBusy.contains(8)) {
          suggestedTime = 'Chiều (Tiết 6-8)';
          reason = 'Khung giờ chiều trống, phù hợp ôn tập nhẹ nhàng.';
        }
        // Ưu tiên 3: Xếp buổi tối
        else if (!dayBusy.contains(11) && !dayBusy.contains(12)) {
          suggestedTime = 'Tối (19:00 - 21:00)';
          reason = skipAfternoon
              ? 'Sáng bạn đã học $morningLoad tiết trên trường, nên nghỉ buổi chiều và ôn nhẹ vào buổi tối.'
              : 'Khung giờ yên tĩnh tập trung.';
        }

        if (suggestedTime != null) {
          if (sp['urgent']) {
            reason = 'SẮP CÓ BÀI KIỂM TRA/DEADLINE! $reason';
          }
          finalSuggestions.add({
            'subject': sp['subject'],
            'dayName': Schedule.dayName(dayToMap),
            'time': suggestedTime,
            'reason': reason,
          });
          break; // Đã tìm được giờ cho môn này trong ngày này, chuyển sang ngày tiếp theo
        }
      }
    }

    if (mounted) {
      setState(() {
        _suggestions = finalSuggestions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_suggestions.isEmpty) return const SizedBox(); // Không có gợi ý thì ẩn đi

    return Card(
      color: Colors.amber.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'GỢI Ý TỰ HỌC THÔNG MINH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._suggestions.map((s) {
              Subject sub = s['subject'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sub.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: sub.color, fontSize: 16),
                            // 2. TỰ ĐỘNG THÊM DẤU "..." NẾU TÊN QUÁ DÀI
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8), // Thêm chút khoảng cách cho chữ khỏi dính vào khung

                        // Khung thời gian giữ nguyên không đụng tới
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            '${s['dayName']} - ${s['time']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['reason'],
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}