import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../models/subject.dart';
import '../models/schedule.dart';
import '../database/db_helper.dart';

class AddEditSubjectScreen extends StatefulWidget {
  final Subject? subject;
  const AddEditSubjectScreen({super.key, this.subject});

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _teacherCtrl, _roomCtrl;
  late int _credits;
  late Color _color;
  final List<Schedule> _schedules = [];

  int _dlgDay = 2, _dlgStart = 1, _dlgEnd = 3;

  static const _colorOptions = [
    Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFF4CAF50),
    Color(0xFFFF9800), Color(0xFF9C27B0), Color(0xFF00BCD4),
    Color(0xFFF44336), Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _teacherCtrl = TextEditingController(text: s?.teacher ?? '');
    _roomCtrl = TextEditingController(text: s?.room ?? '');
    _credits = s?.credits ?? 3;
    _color = s != null ? Color(s.colorValue) : _colorOptions[0];

    if (s != null) {
      _loadExistingSchedules(s.id!);
    }
  }

  Future<void> _loadExistingSchedules(int subjectId) async {
    final existing = await DBHelper.instance.getSchedulesForSubject(subjectId);
    if (mounted) {
      setState(() {
        _schedules.addAll(existing);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa môn học' : 'Thêm môn học'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ten mon hoc
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên môn học *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? 'Nhập tên môn' : null,
            ),
            const SizedBox(height: 12),
            // giang vien
            TextFormField(
              controller: _teacherCtrl,
              decoration: const InputDecoration(labelText: 'Giảng viên *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? 'Nhập tên giảng viên' : null,
            ),
            const SizedBox(height: 12),
            // Phòng học
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(labelText: 'Phòng học *', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty == true ? 'Nhập phòng học' : null,
            ),
            const SizedBox(height: 16),
            // so tin chi
            const Text('Số tín chỉ', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (i) => i + 1).map((n) => ChoiceChip(
                label: Text('$n'),
                selected: _credits == n,
                onSelected: (_) => setState(() => _credits = n),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // mau mon hoc
            const Text('Màu môn học', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 18,
                  child: _color == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            // Lịch học
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm buổi'),
                  onPressed: _showScheduleDialog,
                ),
              ],
            ),
            if (_schedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có lịch học', style: TextStyle(color: Colors.grey.shade500)),
              )
            else
              ..._schedules.asMap().entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(Schedule.dayName(e.value.dayOfWeek)),
                subtitle: Text(
                    'Tiết ${e.value.startPeriod}-${e.value.endPeriod} '
                        '(${Schedule.periodTime(e.value.startPeriod)} - ${Schedule.periodTime(e.value.endPeriod)})'
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => _schedules.removeAt(e.key)),
                ),
              )),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Thêm lịch học'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // chon thu
              DropdownButtonFormField<int>(
                value: _dlgDay,
                decoration: const InputDecoration(labelText: 'Thứ'),
                items: [2, 3, 4, 5, 6, 7, 8].map((d) => DropdownMenuItem(value: d, child: Text(Schedule.dayName(d)))).toList(),
                onChanged: (v) => setDlg(() => _dlgDay = v!),
              ),
              const SizedBox(height: 12),
              // chon tiet
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dlgStart,
                      decoration: const InputDecoration(labelText: 'Tiết bắt đầu'),
                      items: List.generate(12, (i) => i + 1).map((p) => DropdownMenuItem(value: p, child: Text('Tiết $p'))).toList(),
                      onChanged: (v) => setDlg(() => _dlgStart = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dlgEnd,
                      decoration: const InputDecoration(labelText: 'Tiết kết thúc'),
                      items: List.generate(12, (i) => i + 1).map((p) => DropdownMenuItem(value: p, child: Text('Tiết $p'))).toList(),
                      onChanged: (v) => setDlg(() => _dlgEnd = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')
            ),
            FilledButton(
              onPressed: () {
                if (_dlgEnd < _dlgStart) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tiết kết thúc phải >= tiết bắt đầu')),
                  );
                  return;
                }
                setState(() => _schedules.add(Schedule(
                  subjectId: 0,
                  dayOfWeek: _dlgDay,
                  startPeriod: _dlgStart,
                  endPeriod: _dlgEnd,
                )));
                Navigator.pop(ctx);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sp = context.read<SubjectProvider>();
    final subject = Subject(
      id: widget.subject?.id,
      name: _nameCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      room: _roomCtrl.text.trim(),
      colorValue: _color.value,
      credits: _credits,
    );

    if (widget.subject == null) {
      await sp.addSubject(subject, _schedules);
    } else {
      await sp.updateSubject(subject, _schedules);
    }

    if (mounted) Navigator.pop(context);
  }
}