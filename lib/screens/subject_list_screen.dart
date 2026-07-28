import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/grade_provider.dart';
import '../models/subject.dart';
import 'add_edit_subject_screen.dart';
import 'grade_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllGrades());
  }

  Future<void> _loadAllGrades() async {
    if (!mounted) return;
    final subjects = context.read<SubjectProvider>().subjects;
    final gp = context.read<GradeProvider>();
    for (final s in subjects) await gp.loadGrades(s.id!);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SubjectProvider>();
    final gp = context.watch<GradeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Môn học')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditSubjectScreen()),
        ).then((_) {
          // Sau khi quay lại, reload grades cho môn mới
          if (mounted) _loadAllGrades();
        }),
        child: const Icon(Icons.add),
      ),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator())
          : sp.subjects.isEmpty
          ? const Center(
          child: Text(
            'Chưa có môn học nào.\nNhấn + để thêm.',
            textAlign: TextAlign.center,
          ))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sp.subjects.length,
        itemBuilder: (ctx, i) {
          final sub = sp.subjects[i];
          return _SubjectCard(
            subject: sub,
            gp: gp,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => GradeScreen(subject: sub)),
            ).then((_) {
              if (mounted) gp.loadGrades(sub.id!);
            }),
            onEdit: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) =>
                      AddEditSubjectScreen(subject: sub)),
            ).then((_) {
              if (mounted) _loadAllGrades();
            }),
            onDelete: () => _confirmDelete(ctx, sub, sp),
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Subject sub, SubjectProvider sp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Text(
          'Xóa "${sub.name}" sẽ xóa toàn bộ lịch học và điểm số của môn này.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              sp.deleteSubject(sub.id!);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final GradeProvider gp;
  final VoidCallback onTap, onEdit, onDelete;

  const _SubjectCard({
    required this.subject,
    required this.gp,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final score = gp.finalScoreFor(subject.id!);
    final letter = gp.letterFor(subject.id!);
    final hasGrades = gp.gradesFor(subject.id!).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thanh màu bên trái
            Container(width: 5, height: 80, color: subject.color),
            const SizedBox(width: 12),
            // Thông tin môn
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('${subject.teacher} - ${subject.room}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    Text('${subject.credits} tín chỉ',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            ),
            // Điểm (nếu có)
            if (hasGrades)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: score >= 5
                              ? Colors.green.shade700
                              : Colors.red),
                    ),
                    Text(letter,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            // Menu sửa/xóa
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}