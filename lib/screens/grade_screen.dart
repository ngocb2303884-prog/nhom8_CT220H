import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grade_provider.dart';
import '../models/subject.dart';
import '../models/grade.dart';
import '../widgets/material_hub_widget.dart'; // Đã có import

class GradeScreen extends StatefulWidget {
  final Subject subject;
  const GradeScreen({super.key, required this.subject});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  @override
  void initState() {
    super.initState();
    // Load điểm khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GradeProvider>().loadGrades(widget.subject.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GradeProvider>();
    final grades = gp.gradesFor(widget.subject.id!);
    final finalScore = gp.finalScoreFor(widget.subject.id!);
    final letter = gp.letterFor(widget.subject.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: widget.subject.color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Bọc SingleChildScrollView để cuộn toàn bộ trang mượt mà
        child: Column(
          children: [
            // Banner hiển thị tổng kết
            _GradeSummaryBanner(score: finalScore, letter: letter, color: widget.subject.color),

            // Phần danh sách điểm số
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bảng điểm thành phần',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  grades.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('Chưa có đầu điểm nào.')),
                  )
                      : ListView.builder(
                    shrinkWrap: true, // Cho phép ListView nằm trong SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: grades.length,
                    itemBuilder: (ctx, i) => _GradeTile(
                      grade: grades[i],
                      onDelete: () => gp.deleteGrade(grades[i].id!, widget.subject.id!),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1, indent: 16, endIndent: 16),

            // =========================================================
            // 🎯 ĐÃ DÁN MATERIAL HUB WIDGET VÀO ĐÂY
            // =========================================================
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: MaterialHubWidget(subjectId: widget.subject.id!),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.subject.color,
        foregroundColor: Colors.white,
        onPressed: () => _showAddGradeDialog(context, gp),
        child: const Icon(Icons.add_chart),
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context, GradeProvider gp) {
    String selectedType = 'Giữa kỳ';
    double selectedScore = 8.0;
    int selectedWeight = 30; // 30%

    final types = ['Chuyên cần', 'Bài tập', 'Thực hành', 'Giữa kỳ', 'Cuối kỳ', 'Đồ án', 'Khác'];
    final scores = List.generate(101, (i) => i / 10.0);
    final weights = List.generate(20, (i) => (i + 1) * 5);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Thêm đầu điểm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Loại điểm'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDlgState(() => selectedType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: selectedScore,
                      decoration: const InputDecoration(labelText: 'Điểm số'),
                      menuMaxHeight: 300,
                      items: scores.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toStringAsFixed(1)),
                      )).toList(),
                      onChanged: (v) => setDlgState(() => selectedScore = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedWeight,
                      decoration: const InputDecoration(labelText: 'Hệ số (%)'),
                      menuMaxHeight: 300,
                      items: weights.map((w) => DropdownMenuItem(
                        value: w,
                        child: Text('$w%'),
                      )).toList(),
                      onChanged: (v) => setDlgState(() => selectedWeight = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                gp.addGrade(Grade(
                  subjectId: widget.subject.id!,
                  type: selectedType,
                  score: selectedScore,
                  weight: selectedWeight / 100.0,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSummaryBanner extends StatelessWidget {
  final double score;
  final String letter;
  final Color color;

  const _GradeSummaryBanner({required this.score, required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          const Text('ĐIỂM TỔNG KẾT HỆ 10', style: TextStyle(letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(2),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: color),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text('XẾP LOẠI: $letter', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  final Grade grade;
  final VoidCallback onDelete;
  const _GradeTile({required this.grade, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(grade.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Trọng số: ${(grade.weight * 100).toInt()}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              grade.score.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}