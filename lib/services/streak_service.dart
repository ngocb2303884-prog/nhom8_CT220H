import 'dart:math';
import '../database/db_helper.dart';


class StreakService {
  static const List<String> quotes = [
    "Hành trình ngàn dặm bắt đầu từ một bước chân.",
    "Hôm nay chăm chỉ, ngày mai gặt hái thành công!",
    "Kỷ luật là cầu nối giữa mục tiêu và thành tựu.",
    "Đừng hoãn lại việc của hôm nay cho ngày mai.",
    "Mỗi bài tập hoàn thành là một bước tiến gần hơn tới tấm bằng tốt nghiệp!",
  ];

  static String getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }

  // Hàm gọi mỗi khi người dùng hoàn thành 1 bài tập / deadline
  static Future<bool> triggerTaskCompleted() async {
    final info = await DBHelper.instance.getStreakInfo();
    int currentStreak = info?['current_streak'] ?? 0;
    String? lastActiveDateStr = info?['last_active_date'];

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (lastActiveDateStr == null) {
      await DBHelper.instance.updateStreakInfo(1, todayStr);
      return false;
    }

    if (lastActiveDateStr == todayStr) {
      // Hôm nay đã làm rồi, giữ nguyên streak
      return false;
    }

    final lastActiveDate = DateTime.parse(lastActiveDateStr);
    final difference = now.difference(lastActiveDate).inDays;

    if (difference == 1) {
      // Học liên tục sang ngày thứ 2, 3...
      int newStreak = currentStreak + 1;
      await DBHelper.instance.updateStreakInfo(newStreak, todayStr);

      // Thưởng huy hiệu đặc biệt nếu chạm mốc 7 ngày!
      return (newStreak % 7 == 0);
    } else {
      // Bị đứt chuỗi ngắt quãng quá 1 ngày -> Reset về 1
      await DBHelper.instance.updateStreakInfo(1, todayStr);
      return false;
    }
  }
}