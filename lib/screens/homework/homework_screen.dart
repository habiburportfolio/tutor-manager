import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/homework_provider.dart';
import '../../providers/academic_provider.dart';
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
                  'No homework sent yet.\nTap "Send Homework" to assign work to students via SMS, WhatsApp or Messenger with file attachments.',
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
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1A2F6FED),
                      child: Icon(Icons.assignment_rounded, color: kPrimary),
                    ),
                    title: Text(
                      h.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '$cls - $sec • $sub\n${h.studentIds.length} student(s) • ${fmtDate(h.date)}'
                      '${h.attachmentPaths.isNotEmpty ? ' • ${h.attachmentPaths.length} file(s)' : ''}'
                      '${h.sentVia.isNotEmpty ? '\nSent via: ${h.sentVia.join(", ")}' : ''}',
                    ),
                    isThreeLine: true,
                    onLongPress: () => _confirmDelete(context, hwProv, h.id),
                  ),
                );
              },
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
