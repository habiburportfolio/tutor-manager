import 'dart:io';
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
  final List<int> _attachmentSizes = [];
  bool _viaSms = false;
  bool _viaShare = true; // WhatsApp / Messenger / others via native share
  bool _viaTelegram = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_rounded;
    } else if (ext == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description_rounded;
    } else if (ext == 'txt') {
      return Icons.text_snippet_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Colors.purple;
    } else if (ext == 'pdf') {
      return Colors.red;
    } else if (['doc', 'docx'].contains(ext)) {
      return Colors.blue;
    }
    return kPrimary;
  }

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
            decoration: const InputDecoration(
              labelText: 'Homework Title *',
              prefixIcon: Icon(Icons.assignment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description / Instructions',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _classId,
            decoration: const InputDecoration(
              labelText: 'Class *',
              prefixIcon: Icon(Icons.school_outlined),
            ),
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
              prefixIcon: Icon(Icons.grid_view_rounded),
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
            decoration: const InputDecoration(
              labelText: 'Subject *',
              prefixIcon: Icon(Icons.book_outlined),
            ),
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
              constraints: const BoxConstraints(maxHeight: 240),
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
          const SizedBox(height: 18),

          // File Attachment Section with Clear Attached Confirmation Feedback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'File Attachments (Image, PDF, DOC)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              TextButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('Attach File'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (_attachmentPaths.isEmpty)
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey.shade500),
                    const SizedBox(height: 8),
                    const Text(
                      'No files attached yet',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to attach Images, PDF, DOC or Word files',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Success Confirmation Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ ${_attachmentPaths.length} file(s) attached successfully (Ready to send)',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _pickFile,
                    child: const Text(
                      '+ Add More',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Attached Files List Cards
            ...List.generate(_attachmentPaths.length, (index) {
              final fileName = _attachmentNames[index];
              final size = _attachmentSizes.length > index ? _attachmentSizes[index] : 0;
              final color = _getFileColor(fileName);
              final icon = _getFileIcon(fileName);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✓ Attached',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(size),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: 'Remove attachment',
                    onPressed: () {
                      setState(() {
                        _attachmentPaths.removeAt(index);
                        _attachmentNames.removeAt(index);
                        if (_attachmentSizes.length > index) {
                          _attachmentSizes.removeAt(index);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "$fileName"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 18),
          const Text('Send Channels', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          CheckboxListTile(
            value: _viaShare,
            activeColor: kPrimary,
            title: const Row(
              children: [
                Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                SizedBox(width: 8),
                Text('WhatsApp & Share Menu'),
              ],
            ),
            subtitle: const Text('Direct share with file attachments to WhatsApp/groups'),
            onChanged: (v) => setState(() => _viaShare = v ?? false),
          ),
          CheckboxListTile(
            value: _viaTelegram,
            activeColor: const Color(0xFF0088CC),
            title: const Row(
              children: [
                Icon(Icons.send_rounded, color: Color(0xFF0088CC), size: 20),
                SizedBox(width: 8),
                Text('Telegram'),
              ],
            ),
            subtitle: const Text('Broadcast homework message via Telegram chat/channels'),
            onChanged: (v) => setState(() => _viaTelegram = v ?? false),
          ),
          CheckboxListTile(
            value: _viaSms,
            activeColor: kPrimary,
            title: const Row(
              children: [
                Icon(Icons.sms_rounded, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text('SMS Notification'),
              ],
            ),
            subtitle: const Text('Text alert with homework title & description'),
            onChanged: (v) => setState(() => _viaSms = v ?? false),
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
          const SizedBox(height: 30),
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
          if (f.path != null && !_attachmentPaths.contains(f.path)) {
            _attachmentPaths.add(f.path!);
            _attachmentNames.add(f.name);
            int size = f.size;
            if (size == 0) {
              try {
                size = File(f.path!).lengthSync();
              } catch (_) {}
            }
            _attachmentSizes.add(size);
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${result.files.length} file(s) attached successfully!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

    if (_viaTelegram) {
      await ShareService.openTelegramChat(message: message);
      sentVia.add('Telegram');
    }

    if (_viaShare) {
      await ShareService.shareFiles(text: message, filePaths: _attachmentPaths);
      sentVia.add('WhatsApp/Share');
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

