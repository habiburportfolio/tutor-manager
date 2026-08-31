import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/homework_provider.dart';
import '../../providers/academic_provider.dart';
import '../../services/share_service.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import 'send_homework_screen.dart';
import '../meetings/meetings_screen.dart';
import '../../widgets/app_logo.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hwProv = context.watch<HomeworkProvider>();
    final academic = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            const Text('Homework'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_camera_front_rounded),
            tooltip: 'Virtual Meetings (Zoom / Google Meet)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeetingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SendHomeworkScreen()),
        ),
        icon: const Icon(Icons.send_rounded),
        label: const Text('Send Homework'),
      ),
      body: hwProv.homeworks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No homework sent yet.\nTap "Send Homework" to assign work to students via SMS, WhatsApp, Telegram with file attachments.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: hwProv.homeworks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final h = hwProv.homeworks[i];
                final cls = academic.classById(h.classId)?.name ?? '';
                final sec = academic.sectionById(h.sectionId)?.name ?? '';
                final sub = academic.subjectById(h.subjectId)?.name ?? '';
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1A2F6FED),
                      child: Icon(Icons.assignment_rounded, color: kPrimary),
                    ),
                    title: Text(
                      h.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text('$cls - $sec • $sub  |  ${fmtDate(h.date)}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (h.attachmentPaths.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF047857)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${h.attachmentPaths.length} file(s)',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              '${h.studentIds.length} student(s)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _viewHomeworkDetails(context, h, cls, sec, sub, hwProv),
                    onLongPress: () => _confirmDelete(context, hwProv, h.id),
                  ),
                );
              },
            ),
    );
  }

  void _viewHomeworkDetails(
    BuildContext context,
    dynamic h,
    String cls,
    String sec,
    String sub,
    HomeworkProvider prov,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              h.title as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$cls - $sec • $sub  |  ${fmtDate(h.date as DateTime)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if ((h.description as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(h.description as String),
            ],
            if ((h.attachmentPaths as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Attached Files (${(h.attachmentPaths as List).length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: (h.attachmentPaths as List<String>).map((path) {
                  final name = path.split(RegExp(r'[/\\]')).last;
                  return Chip(
                    avatar: const Icon(Icons.insert_drive_file_rounded, size: 16, color: kPrimary),
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ShareService.shareFiles(
                        text: '${h.title}\n${h.description}',
                        filePaths: (h.attachmentPaths as List).cast<String>(),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Re-Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      prov.deleteHomework(h.id as String);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kAccentRed),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HomeworkProvider prov, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Homework Record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              prov.deleteHomework(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }
}

