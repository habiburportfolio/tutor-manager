import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/academic_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/homework_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/section.dart';
import '../../models/subject.dart';
import '../../services/sms_service.dart';
import '../../services/share_service.dart';
import '../../utils/theme.dart';

class SendHomeworkScreen extends StatefulWidget {
  const SendHomeworkScreen({super.key});

  @override
  State<SendHomeworkScreen> createState() => _SendHomeworkScreenState();
}

class _SendHomeworkScreenState extends State<SendHomeworkScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _classId;
  String? _sectionId;
  String? _subjectId;
  final Set<String> _selectedStudentIds = {};
  final List<String> _attachmentPaths = [];
  final List<String> _attachmentNames = [];
  bool _viaSms = false;
  bool _viaShare = true; // WhatsApp / Messenger / others via native share
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final studentsProv = context.watch<StudentProvider>();

    final sections = _classId != null
        ? academic.sectionsForClass(_classId!)
        : <Section>[];
    final subjects = _classId != null
        ? academic.subjectsForClass(_classId!)
        : <Subject>[];
    final candidateStudents = (_classId != null)
        ? studentsProv.byClassSection(_classId!, _sectionId)
        : <dynamic>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Send Homework')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Homework Title *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description / Instructions',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _classId,
            decoration: const InputDecoration(labelText: 'Class *'),
            items: academic.classes
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _classId = v;
              _sectionId = null;
              _subjectId = null;
              _selectedStudentIds.clear();
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _sectionId,
            decoration: const InputDecoration(
              labelText: 'Section (optional = all)',
            ),
            items: sections
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('Section ${s.name}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _sectionId = v;
              _selectedStudentIds.clear();
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _subjectId,
            decoration: const InputDecoration(labelText: 'Subject *'),
            items: subjects
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _subjectId = v),
          ),
          const SizedBox(height: 16),
          if (_classId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${_selectedStudentIds.length}/${candidateStudents.length} selected)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selectedStudentIds.length ==
                        candidateStudents.length) {
                      _selectedStudentIds.clear();
                    } else {
                      _selectedStudentIds
                        ..clear()
                        ..addAll(candidateStudents.map((s) => s.id as String));
                    }
                  }),
                  child: Text(
                    _selectedStudentIds.length == candidateStudents.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: candidateStudents.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No students in this class/section.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidateStudents.length,
                      itemBuilder: (context, i) {
                        final s = candidateStudents[i];
                        final selected = _selectedStudentIds.contains(s.id);
                        return CheckboxListTile(
                          value: selected,
                          title: Text('${s.name} (Roll ${s.roll})'),
                          subtitle: Text(s.guardianPhone),
                          dense: true,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedStudentIds.add(s.id as String);
                            } else {
                              _selectedStudentIds.remove(s.id);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Attachments (image / PDF / DOC / Word)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attachmentNames.asMap().entries.map(
                (e) => Chip(
                  label: Text(e.value, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() {
                    _attachmentPaths.removeAt(e.key);
                    _attachmentNames.removeAt(e.key);
                  }),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.attach_file, size: 18),
                label: const Text('Add File'),
                onPressed: _pickFile,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Send Via', style: const TextStyle(fontWeight: FontWeight.w600)),
          CheckboxListTile(
            value: _viaSms,
            title: const Text('SMS (GP / Robi / any configured provider)'),
            subtitle: const Text(
              'Text-only notification with homework summary',
            ),
            onChanged: (v) => setState(() => _viaSms = v ?? false),
          ),
          CheckboxListTile(
            value: _viaShare,
            title: const Text('WhatsApp / Messenger / Share'),
            subtitle: const Text('Opens share sheet with attached files'),
            onChanged: (v) => setState(() => _viaShare = v ?? false),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _sending ? null : _sendHomework,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _sending
                  ? 'Sending...'
                  : 'Send to ${_selectedStudentIds.length} Student(s)',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      setState(() {
        for (final f in result.files) {
          if (f.path != null) {
            _attachmentPaths.add(f.path!);
            _attachmentNames.add(f.name);
          }
        }
      });
    }
  }

  Future<void> _sendHomework() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _classId == null ||
        _subjectId == null ||
        _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill title, class, subject and select at least one student.',
          ),
        ),
      );
      return;
    }

    setState(() => _sending = true);

    final academic = context.read<AcademicProvider>();
    final studentsProv = context.read<StudentProvider>();
    final hwProv = context.read<HomeworkProvider>();
    final settings = context.read<SettingsProvider>();

    final className = academic.classById(_classId!)?.name ?? '';
    final subjectName = academic.subjectById(_subjectId!)?.name ?? '';
    final message =
        'Homework: ${_titleCtrl.text.trim()}\nClass: $className | Subject: $subjectName\n${_descCtrl.text.trim()}\n- ${settings.centerName}';

    final List<String> sentVia = [];

    if (_viaSms) {
      final smsService = SmsService(settings);
      final phones = _selectedStudentIds
          .map((id) => studentsProv.byId(id)?.guardianPhone ?? '')
          .where((p) => p.isNotEmpty)
          .toList();
      await smsService.sendBulkSms(phones: phones, message: message);
      sentVia.add('SMS');
    }

    if (_viaShare) {
      await ShareService.shareFiles(text: message, filePaths: _attachmentPaths);
      sentVia.add('WhatsApp/Messenger/Share');
    }

    await hwProv.addHomework(
      classId: _classId!,
      sectionId: _sectionId ?? '',
      subjectId: _subjectId!,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      studentIds: _selectedStudentIds.toList(),
      attachmentPaths: _attachmentPaths,
      sentVia: sentVia,
    );

    setState(() => _sending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Homework sent to ${_selectedStudentIds.length} student(s)!',
          ),
          backgroundColor: kAccentGreen,
        ),
      );
      Navigator.pop(context);
    }
  }
}
