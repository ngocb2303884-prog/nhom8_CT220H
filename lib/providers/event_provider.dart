import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/notification_service.dart';

class EventProvider extends ChangeNotifier {
  List<AcademicEvent> _events = [];
  bool _loading = false;
  int _streakDays = 0;
  int get streakDays => _streakDays;
  List<AcademicEvent> get events => _events;
  bool get loading => _loading;

  Future<void> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _streakDays = prefs.getInt('current_streak') ?? 0;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _loading = true;
    _events = await DBHelper.instance.getAllEvents();
    _loading = false;
    await loadStreak();
    notifyListeners();
  }
  // THÊM MỚI: Hàm xử lý khi bấm nút Check hoàn thành deadline (Bản nâng cấp)
  Future<void> markEventAsDone(int id) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Lấy dữ liệu ngày lưu cuối cùng
    String? lastActiveDateStr = prefs.getString('last_active_date');

    // 2. Lấy ngày hiện tại (Chỉ lấy ngày/tháng/năm, gọt bỏ phần giờ/phút/giây để so sánh cho chuẩn)
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastActiveDateStr != null) {
      DateTime lastActiveDate = DateTime.parse(lastActiveDateStr);

      // Tính khoảng cách giữa hôm nay và lần cuối cùng làm bài
      int differenceDays = today.difference(lastActiveDate).inDays;

      if (differenceDays == 0) {
        // Trường hợp A: Hôm nay đã hoàn thành 1 bài rồi. Giờ làm thêm bài nữa.
        // -> Giữ nguyên chuỗi, không cộng thêm.
        print("Hôm nay đã tính chuỗi rồi, không cộng thêm.");
      } else if (differenceDays == 1) {
        // Trường hợp B: Hôm qua đã làm, hôm nay làm tiếp.
        // -> Tăng chuỗi lên 1
        _streakDays++;
      } else {
        // Trường hợp C: Bỏ lỡ quá 1 ngày (ví dụ cách 2 ngày mới vô làm lại)
        // -> Reset chuỗi về 1 (Ngày đầu tiên của chuỗi mới)
        _streakDays = 1;
      }
    } else {
      // Trường hợp D: Lần đầu tiên sử dụng app
      _streakDays = 1;
    }

    // 3. Lưu lại số chuỗi và đánh dấu ngày hôm nay là ngày cuối cùng làm bài
    await prefs.setInt('current_streak', _streakDays);
    await prefs.setString('last_active_date', today.toIso8601String());

    // 4. Báo cho giao diện cập nhật con số
    notifyListeners();
  }

  Future<void> addEvent(AcademicEvent e) async {
    final id = await DBHelper.instance.insertEvent(e);
    await loadEvents();

    // lich thi nhac truoc 1 ngay
    // deadline nhac truoc 2 tieng truoc gio nop
    DateTime alertTime = e.dateTime;
    if (e.type == 'Lịch thi') {
      alertTime = e.dateTime.subtract(const Duration(days: 1));
    } else {
      alertTime = e.dateTime.subtract(const Duration(hours: 2));
      //alertTime = DateTime.now().add(const Duration(seconds: 5));
    }

    await NotificationService.instance.scheduleAlert(
      id,
      '🔔 Sắp đến hạn: ${e.type}',
      'Môn học có lịch: ${e.title} vào lúc ${e.dateTime.hour}:${e.dateTime.minute.toString().padLeft(2, '0')}',
      alertTime,
    );
    print("✅ ĐÃ GỬI LỆNH ĐẶT BÁO THỨC LÚC: $alertTime");
  }

  Future<void> deleteEvent(int id) async {
    await DBHelper.instance.deleteEvent(id);
    await NotificationService.instance.cancelAlert(id);
    await loadEvents();
  }
}