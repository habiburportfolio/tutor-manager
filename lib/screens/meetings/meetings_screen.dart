import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/contact_service.dart';
import '../../services/share_service.dart';
import '../../models/meeting.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

/// Lets the coaching center create/store Zoom or Google Meet virtual class
/// links, open them, and quickly share them (via SMS or WhatsApp/share
/// sheet) with guardians of a chosen class/section.
///
/// NOTE: This does NOT create meetings via the Zoom/Google APIs (that
/// requires a registered developer/business account with OAuth). Instead
/// the admin pastes a link they already created on zoom.us or
/// meet.google.com (or taps "Start Instant Google Meet" which opens
/// meet.google.com/new to generate one on the spot), and the app takes
/// care of storing, opening and broadcasting that link to students.
class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetings = context.watch<MeetingProvider>();
    final academic = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Meetings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeetingDialog(context),
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('New Meeting'),
      ),
      body: meetings.meetings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_camera_front_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No virtual meetings yet.\nTap "New Meeting" to add a Zoom or Google Meet link and share it with a class.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openInstantMeet(context),
                          icon: const Icon(Icons.video_call_outlined),
                          label: const Text('Start Instant Google Meet'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: meetings.meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = meetings.meetings[i];
                final cls = m.classId != null
                    ? academic.classById(m.classId!)?.name ?? 'Unknown Class'
                    : 'All Classes';
                final sec = m.sectionId != null
                    ? academic.sectionById(m.sectionId!)?.name
                    : null;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: m.platform == 'Zoom'
                          ? const Color(0x1A2D8CFF)
                          : const Color(0x1A34A853),
                      child: Icon(
                        Icons.video_camera_front_rounded,
                        color: m.platform == 'Zoom'
                            ? const Color(0xFF2D8CFF)
                            : const Color(0xFF34A853),
                      ),
                    ),
                    title: Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${m.platform} • $cls${sec != null ? ' - Section $sec' : ''}\n'
                      '${fmtDateTime(m.scheduledAt)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'open') {
                          _openLink(context, m.link);
                        } else if (v == 'share') {
                          _shareMeeting(context, m, academic);
                        } else if (v == 'sms') {
                          _smsMeeting(context, m);
                        } else if (v == 'edit') {
                          _showAddMeetingDialog(context, existing: m);
                        } else if (v == 'delete') {
                          _confirmDelete(context, meetings, m.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('Open / Join')),
                        PopupMenuItem(
                          value: 'share',
                          child: Text('Share Link (WhatsApp/Share)'),
                        ),
                        PopupMenuItem(
                          value: 'sms',
                          child: Text('SMS Link to Class'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _openLink(context, m.link),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openLink(BuildContext context, String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the meeting link.')),
      );
    }
  }

  Future<void> _openInstantMeet(BuildContext context) async {
    await _openLink(context, 'https://meet.google.com/new');
  }

  Future<void> _shareMeeting(
    BuildContext context,
    Meeting m,
    AcademicProvider academic,
  ) async {
    final cls = m.classId != null
        ? academic.classById(m.classId!)?.name ?? ''
        : 'All Classes';
    final text =
        '${m.platform} Class: ${m.title}\n$cls\nTime: ${fmtDateTime(m.scheduledAt)}\nJoin: ${m.link}';
    await ShareService.shareFiles(text: text);
  }

  Future<void> _smsMeeting(BuildContext context, Meeting m) async {
    final studentsProv = context.read<StudentProvider>();
    List<dynamic> recipients;
    if (m.classId == null) {
      recipients = studentsProv.students;
    } else {
      recipients = studentsProv.byClassSection(m.classId!, m.sectionId);
    }
    final phones = recipients
        .map((s) => s.guardianPhone as String)
        .where((p) => p.isNotEmpty)
        .toList();
    if (phones.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No guardian phone numbers found.')),
        );
      }
      return;
    }
    final body =
        '${m.platform} Class "${m.title}" at ${fmtDateTime(m.scheduledAt)}. Join: ${m.link}';
    if (context.mounted) {
      await ContactService.sendGroupSms(context, phones, body: body);
    }
  }

  void _confirmDelete(
    BuildContext context,
    MeetingProvider meetings,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meeting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              meetings.deleteMeeting(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }

  void _showAddMeetingDialog(BuildContext context, {Meeting? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title);
    final linkCtrl = TextEditingController(text: existing?.link);
    final noteCtrl = TextEditingController(text: existing?.note);
    String platform = existing?.platform ?? 'Zoom';
    String? classId = existing?.classId;
    String? sectionId = existing?.sectionId;
    DateTime scheduledAt = existing?.scheduledAt ?? DateTime.now();

    final meetings = context.read<MeetingProvider>();
    final academic = context.read<AcademicProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final sections = classId != null
              ? academic.sectionsForClass(classId!)
              : <dynamic>[];

          Future<void> pickDateTime() async {
            final date = await showDatePicker(
              context: ctx,
              initialDate: scheduledAt,
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (date == null) return;
            final time = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay.fromDateTime(scheduledAt),
            );
            if (time == null) return;
            setState(() {
              scheduledAt = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }

          return AlertDialog(
            title: Text(
              existing == null ? 'New Virtual Meeting' : 'Edit Meeting',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Title *',
                      hintText: 'e.g. Physics Live Class',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: platform,
                    decoration: const InputDecoration(labelText: 'Platform'),
                    items: const [
                      DropdownMenuItem(value: 'Zoom', child: Text('Zoom')),
                      DropdownMenuItem(
                        value: 'Google Meet',
                        child: Text('Google Meet'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => platform = v ?? platform),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkCtrl,
                    decoration: InputDecoration(
                      labelText: 'Meeting Link *',
                      hintText: platform == 'Zoom'
                          ? 'https://zoom.us/j/xxxxxxxxx'
                          : 'https://meet.google.com/xxx-xxxx-xxx',
                      suffixIcon: platform == 'Google Meet'
                          ? IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Create instant Google Meet link',
                              onPressed: () async {
                                await launchUrl(
                                  Uri.parse('https://meet.google.com/new'),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: classId,
                    decoration: const InputDecoration(
                      labelText: 'Class (optional = all)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...academic.classes.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      classId = v;
                      sectionId = null;
                    }),
                  ),
                  if (classId != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: sectionId,
                      decoration: const InputDecoration(
                        labelText: 'Section (optional = all)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Sections'),
                        ),
                        ...sections.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.id as String,
                            child: Text('Section ${s.name}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => sectionId = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date & Time *',
                        suffixIcon: Icon(Icons.event_rounded),
                      ),
                      child: Text(fmtDateTime(scheduledAt)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty ||
                      linkCtrl.text.trim().isEmpty) {
                    return;
                  }
                  if (existing == null) {
                    meetings.addMeeting(
                      title: titleCtrl.text.trim(),
                      platform: platform,
                      link: linkCtrl.text.trim(),
                      classId: classId,
                      sectionId: sectionId,
                      scheduledAt: scheduledAt,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                  } else {
                    existing.title = titleCtrl.text.trim();
                    existing.platform = platform;
                    existing.link = linkCtrl.text.trim();
                    existing.classId = classId;
                    existing.sectionId = sectionId;
                    existing.scheduledAt = scheduledAt;
                    existing.note = noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim();
                    meetings.updateMeeting(existing);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
