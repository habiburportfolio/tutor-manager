import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/contact_service.dart';
import '../../services/share_service.dart';
import '../../utils/theme.dart';

/// Lets the coaching center staff pick "All Students" or a specific class
/// (optionally narrowed to a section) and then quickly reach them via:
///  - Group SMS
///  - WhatsApp broadcast / direct chat
///  - Telegram broadcast
///  - Rapid Call List
class GroupContactScreen extends StatefulWidget {
  const GroupContactScreen({super.key});

  @override
  State<GroupContactScreen> createState() => _GroupContactScreenState();
}

class _GroupContactScreenState extends State<GroupContactScreen> {
  String? _classId; // null = All Classes
  String? _sectionId; // null = All Sections (only relevant if _classId set)
  final Set<String> _selectedIds = {};
  bool _selectionInitialized = false;
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final settings = context.watch<SettingsProvider>();

    List<dynamic> candidates = studentsProv.students;
    if (_classId != null) {
      candidates = studentsProv.byClassSection(_classId!, _sectionId);
    }

    if (!_selectionInitialized) {
      _selectedIds
        ..clear()
        ..addAll(candidates.map((s) => s.id as String));
      _selectionInitialized = true;
    }

    final sections = _classId != null
        ? academic.sectionsForClass(_classId!)
        : <dynamic>[];

    final selectedStudents = candidates
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    final selectedPhones = selectedStudents
        .map((s) => (s.guardianPhone as String).isNotEmpty ? (s.guardianPhone as String) : (s.studentPhone as String? ?? ''))
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Group Call, SMS & Social')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _classId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.school_outlined),
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
                    _classId = v;
                    _sectionId = null;
                    _selectionInitialized = false;
                  }),
                ),
                if (_classId != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _sectionId,
                    decoration: const InputDecoration(
                      labelText: 'Section (optional = all)',
                      prefixIcon: Icon(Icons.grid_view_rounded),
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
                    onChanged: (v) => setState(() {
                      _sectionId = v;
                      _selectionInitialized = false;
                    }),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Message to Broadcast',
                    hintText: 'Type the message to send via SMS, WhatsApp, or Telegram…',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedIds.length}/${candidates.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selectedIds.length == candidates.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(candidates.map((s) => s.id as String));
                    }
                  }),
                  child: Text(
                    _selectedIds.length == candidates.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: candidates.isEmpty
                ? const Center(child: Text('No students found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: candidates.length,
                    itemBuilder: (context, i) {
                      final s = candidates[i];
                      final selected = _selectedIds.contains(s.id);
                      final phone = (s.guardianPhone as String).isNotEmpty
                          ? (s.guardianPhone as String)
                          : (s.studentPhone as String? ?? '');

                      return CheckboxListTile(
                        value: selected,
                        dense: true,
                        title: Text('${s.name} (Roll ${s.roll})'),
                        subtitle: Text(
                          phone.isEmpty ? 'No phone number' : phone,
                        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (phone.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                                tooltip: 'Call',
                                onPressed: () => ContactService.makePhoneCall(context, phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                tooltip: 'WhatsApp',
                                onPressed: () => ContactService.openWhatsApp(
                                  context,
                                  phone,
                                  message: _messageCtrl.text.trim().isNotEmpty
                                      ? _messageCtrl.text.trim()
                                      : 'Hello from ${settings.centerName}',
                                ),
                              ),
                            ],
                          ],
                        ),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedIds.add(s.id as String);
                          } else {
                            _selectedIds.remove(s.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedPhones.isEmpty
                              ? null
                              : () => ContactService.sendGroupSms(
                                  context,
                                  selectedPhones,
                                  body: _messageCtrl.text.trim(),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                          ),
                          icon: const Icon(Icons.sms_rounded, size: 18),
                          label: Text('SMS (${selectedPhones.length})', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedStudents.isEmpty
                              ? null
                              : () => ShareService.shareFiles(
                                  text: _messageCtrl.text.trim().isNotEmpty
                                      ? _messageCtrl.text.trim()
                                      : 'Notice from ${settings.centerName}',
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('WhatsApp / Share', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ShareService.openTelegramChat(
                              message: _messageCtrl.text.trim().isNotEmpty
                                  ? _messageCtrl.text.trim()
                                  : 'Notice from ${settings.centerName}',
                            );
                          },
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF0088CC), size: 18),
                          label: const Text('Telegram', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedStudents.isEmpty
                              ? null
                              : () => _openCallList(context, selectedStudents, settings.centerName),
                          icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 18),
                          label: const Text('Rapid Call List', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCallList(BuildContext context, List<dynamic> students, String centerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap to Call or WhatsApp each guardian one by one',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: students.length,
                itemBuilder: (ctx2, i) {
                  final s = students[i];
                  final phone = (s.guardianPhone as String).isNotEmpty
                      ? (s.guardianPhone as String)
                      : (s.studentPhone as String? ?? '');

                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(s.name as String),
                    subtitle: Text(
                      phone.isEmpty ? 'No phone number' : phone,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (phone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                            onPressed: () => ContactService.openWhatsApp(
                              ctx2,
                              phone,
                              message: _messageCtrl.text.trim().isNotEmpty
                                  ? _messageCtrl.text.trim()
                                  : 'Hello from $centerName regarding ${s.name}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: Color(0xFF10B981)),
                            onPressed: () => ContactService.makePhoneCall(
                              ctx2,
                              phone,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

