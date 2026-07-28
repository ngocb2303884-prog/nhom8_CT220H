import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/subject_provider.dart';
import '../models/event.dart';
import '../models/subject.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Deadline & Lịch thi', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ep.loading
          ? const Center(child: CircularProgressIndicator())
          : ep.events.isEmpty
          ? const Center(child: Text('Chưa có lịch thi hay deadline nào.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ep.events.length,
        itemBuilder: (ctx, i) {
          final ev = ep.events[i];
          final isDeadline = ev.type == 'Deadline';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                isDeadline ? Icons.assignment_late : Icons.gavel,
                color: isDeadline ? Colors.orange : Colors.red,
              ),
              title: Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${ev.type} - Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(ev.dateTime)}\nLưu ý: ${ev.notes}'
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () {
                  // 1. Ghi nhận hoàn thành để tăng chuỗi ngày (dùng ev.id!)
                  context.read<EventProvider>().markEventAsDone(ev.id!);

                  // 2. Xóa sự kiện đó khỏi danh sách sau khi đã tick xanh
                  ep.deleteEvent(ev.id!);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, ep),
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, EventProvider ep) {
    final subjects = context.read<SubjectProvider>().subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy thêm môn học trước khi tạo sự kiện!')),
      );
      return;
    }

    Subject selectedSubject = subjects[0];
    String selectedType = 'Deadline';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 23, minute: 59);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Thêm nhắc nhở mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Subject>(
                  value: selectedSubject,
                  decoration: const InputDecoration(labelText: 'Môn học'),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setDlgState(() => selectedSubject = v!),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Phân loại'),
                  items: ['Deadline', 'Lịch thi'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDlgState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                // Nút chọn ngày
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDlgState(() => selectedDate = d);
                  },
                ),
                // Nút chọn giờ
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Giờ: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime);
                    if (t != null) setDlgState(() => selectedTime = t);
                  },
                ),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Ghi chú / Phòng thi')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final finalDateTime = DateTime(
                    selectedDate.year, selectedDate.month, selectedDate.day,
                    selectedTime.hour, selectedTime.minute
                );
                ep.addEvent(AcademicEvent(
                  subjectId: selectedSubject.id!,
                  title: '[${selectedSubject.name}] ${notesCtrl.text.trim().isEmpty ? selectedType : notesCtrl.text.trim()}',
                  type: selectedType,
                  dateTime: finalDateTime,
                  notes: notesCtrl.text,
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