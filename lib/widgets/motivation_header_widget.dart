import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/db_helper.dart';
import '../providers/event_provider.dart';
import '../services/streak_service.dart';

class MotivationHeaderWidget extends StatefulWidget {
  const MotivationHeaderWidget({Key? key}) : super(key: key);

  @override
  _MotivationHeaderWidgetState createState() => _MotivationHeaderWidgetState();
}

class _MotivationHeaderWidgetState extends State<MotivationHeaderWidget> {
  int _streakCount = 0;
  String _quote = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await DBHelper.instance.getStreakInfo();
    setState(() {
      _streakCount = info?['current_streak'] ?? 0;
      _quote = StreakService.getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasBadge = _streakCount >= 7;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${context.watch<EventProvider>().streakDays} Ngày liên tiếp',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              if (hasBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.military_tech, color: Colors.black87, size: 18),
                      SizedBox(width: 4),
                      Text("Huy hiệu 7 ngày", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            children: [
              const Icon(Icons.format_quote, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _quote,
                  style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}