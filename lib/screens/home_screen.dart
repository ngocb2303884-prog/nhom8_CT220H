import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/grade_provider.dart';
import '../models/schedule.dart';
import 'timetable_screen.dart';
import 'subject_list_screen.dart';
import '../database/db_helper.dart';
import 'event_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'smart_reminder_card.dart';
import '../widgets/motivation_header_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _DashboardTab(),
    TimetableScreen(),
    SubjectListScreen(),
    EventScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Thời khóa biểu',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Môn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.notification_important_outlined),
            selectedIcon: Icon(Icons.notification_important),
            label: 'Deadline & Thi',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB TỔNG QUAN (DASHBOARD)
// ==========================================
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _loaded = false;
  List<Map<String, dynamic>> _todaySchedule = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loaded = false);
    final sp = context.read<SubjectProvider>();
    final gp = context.read<GradeProvider>();

    await sp.loadSubjects();

    final todayDay = DateTime.now().weekday + 1;
    final todayList = <Map<String, dynamic>>[];

    for (final sub in sp.subjects) {
      await gp.loadGrades(sub.id!);
      final schedules = await DBHelper.instance.getSchedulesForSubject(sub.id!);
      for (final sch in schedules) {
        if (sch.dayOfWeek == todayDay) {
          todayList.add({
            'subject': sub,
            'schedule': sch,
          });
        }
      }
    }

    todayList.sort((a, b) => (a['schedule'] as Schedule).startPeriod.compareTo((b['schedule'] as Schedule).startPeriod));

    if (mounted) {
      setState(() {
        _todaySchedule = todayList;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final gp = context.watch<GradeProvider>();
    final dayLabel = Schedule.dayName(DateTime.now().weekday + 1);

    double totalGpaPoints = 0;
    int totalCredits = 0;
    for (final sub in subjects) {
      if (gp.gradesFor(sub.id!).isNotEmpty) {
        totalGpaPoints += gp.gpa4For(sub.id!) * sub.credits;
        totalCredits += sub.credits;
      }
    }
    final cumulativeGpa = totalCredits > 0 ? (totalGpaPoints / totalCredits) : 0.0;

    String statusText = 'Chưa có điểm';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.school;

    if (totalCredits > 0) {
      if (cumulativeGpa < 1.0) {
        statusText = 'CẢNH BÁO HỌC VỤ (Dưới 1.0)';
        statusColor = Colors.red.shade700;
        statusIcon = Icons.warning_amber_rounded;
      } else if (cumulativeGpa < 2.0) {
        statusText = 'Học lực: YẾU (Nguy cơ)';
        statusColor = Colors.orange;
        statusIcon = Icons.trending_down;
      } else if (cumulativeGpa < 2.5) {
        statusText = 'Học lực: TRUNG BÌNH';
        statusColor = Colors.blue;
        statusIcon = Icons.remove;
      } else if (cumulativeGpa < 3.2) {
        statusText = 'Học lực: KHÁ';
        statusColor = Colors.green;
        statusIcon = Icons.trending_up;
      } else if (cumulativeGpa < 3.6) {
        statusText = 'Học lực: GIỎI';
        statusColor = Colors.teal;
        statusIcon = Icons.star_half;
      } else {
        statusText = 'Học lực: XUẤT SẮC';
        statusColor = Colors.purple;
        statusIcon = Icons.star;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MotivationHeaderWidget(),

            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              margin: const EdgeInsets.only(bottom: 24),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                        'GPA TÍCH LŨY (HỆ 4.0)',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cumulativeGpa.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary
                      ),
                    ),
                    Text(
                        'Dựa trên $totalCredits tín chỉ đã có điểm',
                        style: TextStyle(color: Colors.grey.shade700)
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        // Cập nhật dùng .withValues(alpha: ...)
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TargetGradeCard(
              subjects: subjects,
              gradeProvider: gp,
              currentGpa: cumulativeGpa,
              currentCredits: totalCredits,
            ),
            const SizedBox(height: 16),

            const SmartStudyPlanner(),
            _SectionLabel('Lịch hôm nay - $dayLabel'),
            const SizedBox(height: 8),
            if (!_loaded)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_todaySchedule.isEmpty)
              const _EmptyCard('Không có lịch học hôm nay. Nghỉ ngơi thôi!')
            else
              ..._todaySchedule.map((s) => _TodayTile(data: s)),

            const SizedBox(height: 24),

            const _SectionLabel('Điểm theo môn'),
            const SizedBox(height: 8),
            if (subjects.isEmpty)
              const _EmptyCard('Chưa có môn học. Thêm từ tab "Môn học".')
            else
              ...subjects.map((sub) {
                final score10 = gp.finalScoreFor(sub.id!);
                final score4 = gp.gpa4For(sub.id!);
                final letter = gp.letterFor(sub.id!);
                final hasGrades = gp.gradesFor(sub.id!).isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sub.color,
                      child: Text(
                        sub.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${sub.credits} tín chỉ - GV: ${sub.teacher}'),
                    trailing: hasGrades
                        ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${score10.toStringAsFixed(1)} / $letter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: score10 >= 5 ? Colors.green.shade700 : Colors.red,
                          ),
                        ),
                        Text('Hệ 4: ${score4.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                        : const Text('-', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ),
    );
  }
}

class _TodayTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TodayTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final sub = data['subject'];
    final sch = data['schedule'] as Schedule;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, color: sub.color),
            Expanded(
              child: ListTile(
                title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Phòng: ${sub.room}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tiết ${sch.startPeriod}-${sch.endPeriod}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${Schedule.periodTime(sch.startPeriod)} - ${Schedule.periodTime(sch.endPeriod)}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetGradeCard extends StatefulWidget {
  final List<dynamic> subjects;
  final dynamic gradeProvider;
  final double currentGpa;
  final int currentCredits;

  const TargetGradeCard({
    Key? key,
    required this.subjects,
    required this.gradeProvider,
    required this.currentGpa,
    required this.currentCredits,
  }) : super(key: key);

  @override
  State<TargetGradeCard> createState() => _TargetGradeCardState();
}

class _TargetGradeCardState extends State<TargetGradeCard> {
  double targetGpa = 3.2;
  double? requiredGpa;
  int remainingCredits = 0;
  String message = '';
  Color messageColor = Colors.black;

  void _calculateTarget() {
    remainingCredits = 0;

    for (final sub in widget.subjects) {
      if (widget.gradeProvider.gradesFor(sub.id!).isEmpty) {
        remainingCredits += sub.credits as int;
      }
    }

    if (remainingCredits == 0) {
      setState(() {
        message = 'Bạn không còn môn nào chưa có điểm!';
        messageColor = Colors.blue;
        requiredGpa = null;
      });
      return;
    }

    int totalCredits = widget.currentCredits + remainingCredits;
    double totalRequiredPoints = targetGpa * totalCredits;
    double currentPoints = widget.currentGpa * widget.currentCredits;

    double neededPoints = totalRequiredPoints - currentPoints;
    double neededGpa = neededPoints / remainingCredits;

    setState(() {
      requiredGpa = neededGpa;
      if (neededGpa > 4.0) {
        message = 'Bất khả thi! Bạn cần đạt ${neededGpa.toStringAsFixed(2)}/4.0 (Vượt quá giới hạn tối đa). Vui lòng hạ mục tiêu.';
        messageColor = Colors.red;
      } else if (neededGpa <= 0) {
        message = 'Chúc mừng! Chắc chắn bạn đã đạt mục tiêu này rồi.';
        messageColor = Colors.purple;
      } else {
        message = 'Bạn cần đạt trung bình ${neededGpa.toStringAsFixed(2)}/4.0 cho $remainingCredits tín chỉ còn lại.';
        messageColor = Colors.green.shade700;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'DỰ PHÓNG ĐIỂM SỐ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Nhập GPA mục tiêu (Hệ 4.0) muốn đạt lúc ra trường:'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: targetGpa,
                    min: 2.0,
                    max: 4.0,
                    divisions: 20,
                    label: targetGpa.toStringAsFixed(1),
                    onChanged: (val) => setState(() => targetGpa = val),
                  ),
                ),
                Text(
                  targetGpa.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
                onPressed: _calculateTarget,
                child: const Text('TÍNH TOÁN YÊU CẦU'),
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Cập nhật dùng .withValues(alpha: ...)
                  color: messageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: messageColor, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}