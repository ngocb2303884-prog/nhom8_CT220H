import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../database/db_helper.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const List<int> _days = [2, 3, 4, 5, 6, 7, 8];
  static const int _maxPeriod = 12;
  static const double _cellH = 50.0;
  static const double _cellW = 100.0;
  static const double _periodW = 50.0;

  Map<int, List<Map<String, dynamic>>> _scheduleMap = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<int, List<Map<String, dynamic>>> map = {};
    for (final d in _days) {
      map[d] = await DBHelper.instance.getSchedulesForDay(d);
    }
    if (mounted) setState(() { _scheduleMap = map; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời khóa biểu'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _headerCell('Tiết', _periodW, primary),
                ..._days.map((d) => _headerCell(Schedule.dayName(d), _cellW, primary)),
              ],
            ),
            // Các hàng tiết
            ...List.generate(_maxPeriod, (i) {
              final period = i + 1;
              return Row(
                children: [
                  _periodCell(period),
                  ..._days.map((d) => _buildCell(d, period)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width, Color bg) {
    return Container(
      width: width, height: 38,
      color: bg,
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _periodCell(int period) {
    return Container(
      width: _periodW, height: _cellH,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$period', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(Schedule.periodTime(period), style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildCell(int day, int period) {
    final schedules = _scheduleMap[day] ?? [];

    // Tìm môn BẮT ĐẦU ở tiết này
    final match = schedules.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s!['start_period'] == period,
      orElse: () => null,
    );

    // Kiểm tra tiết này nằm trong môn đã bắt đầu trước đó
    final isContinuation = schedules.any(
          (s) => s['start_period'] < period && s['end_period'] >= period,
    );

    if (isContinuation) {
      final cont = schedules.firstWhere(
            (s) => s['start_period'] < period && s['end_period'] >= period,
      );
      final color = Color(cont['color_value'] as int);
      return Container(
        width: _cellW, height: _cellH,
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          border: Border(
            left: BorderSide(color: color.withOpacity(0.5), width: 1.5),
            right: BorderSide(color: Colors.grey.shade200, width: 0.5),
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
      );
    }

    if (match == null) {
      return Container(
        width: _cellW, height: _cellH,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
      );
    }

    final color = Color(match['color_value'] as int);
    final end = match['end_period'] as int;

    return Container(
      width: _cellW, height: _cellH,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          match['subject_name'] as String,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        if (end > period)
          Text('T$end', style: TextStyle(color: color.withOpacity(0.8), fontSize: 9)),
      ]),
    );
  }
}