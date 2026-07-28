import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/db_helper.dart';
import '../models/resource.dart';
import '../services/streak_service.dart'; // 1. Đã bổ sung import StreakService

class MaterialHubWidget extends StatefulWidget {
  final int subjectId;

  const MaterialHubWidget({Key? key, required this.subjectId}) : super(key: key);

  @override
  _MaterialHubWidgetState createState() => _MaterialHubWidgetState();
}

class _MaterialHubWidgetState extends State<MaterialHubWidget> {
  List<SubjectResource> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.instance.getResourcesBySubject(widget.subjectId);
    setState(() {
      _resources = data.map((json) => SubjectResource.fromMap(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _openUrl(String urlString) async {
    String formattedUrl = urlString;
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final Uri uri = Uri.parse(formattedUrl);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {

      // 2. DÁN LOGIC CỘNG STREAK VÀO ĐÂY (Khi mở link tài liệu thành công)
      bool getReward = await StreakService.triggerTaskCompleted();

      if (!mounted) return;

      if (getReward) {
        // Thông báo khi chạm mốc 7 ngày liên tiếp
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.military_tech, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text("Chúc mừng!"),
              ],
            ),
            content: const Text(
              "Bạn đã tích cực học tập 7 ngày liên tiếp! Bạn nhận được Huy hiệu Chăm chỉ!",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tuyệt vời"),
              ),
            ],
          ),
        );
      } else {
        // Nhắc nhẹ đã ghi nhận streak
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔥 Đã ghi nhận thói quen học tập hôm nay!"),
            duration: Duration(seconds: 2),
          ),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở liên kết: $urlString')),
      );
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Tài nguyên / Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên tài liệu (VD: Slide bài giảng)'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Đường dẫn URL (VD: drive.google.com/...)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final newRes = SubjectResource(
                  subjectId: widget.subjectId,
                  title: titleController.text.trim(),
                  url: urlController.text.trim(),
                );
                await DBHelper.instance.insertResource(newRes.toMap());
                Navigator.pop(ctx);
                _loadResources();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tài liệu & Link liên kết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_link, color: Colors.indigo),
                onPressed: _showAddDialog,
              ),
            ],
          ),
        ),
        _isLoading
            ? const CircularProgressIndicator()
            : _resources.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Chưa có tài liệu nào. Bấm nút + để đính kèm link!'),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _resources.length,
          itemBuilder: (ctx, i) {
            final res = _resources[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  res.url.contains('drive')
                      ? Icons.cloud_queue
                      : res.url.contains('zoom') || res.url.contains('meet')
                      ? Icons.video_call
                      : Icons.link,
                  color: Colors.indigo,
                ),
                title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(res.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () => _openUrl(res.url),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await DBHelper.instance.deleteResource(res.id!);
                        _loadResources();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}