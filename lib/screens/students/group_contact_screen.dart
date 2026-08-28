import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../services/contact_service.dart';
import '../../utils/theme.dart';

/// Lets the coaching center staff pick "All Students" or a specific class
/// (optionally narrowed to a section) and then, with one tap, either:
///  - send a single SMS to the whole selected group at once (native
///    multi-recipient `sms:` compose screen), or
///  - call through the group one guardian at a time via a simple list
///    (a real phone can only dial one number at a time, so "group call"
///    is implemented as a fast one-tap-per-contact call list instead of a
///    literal simultaneous conference call).
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

    List<dynamic> candidates = studentsProv.students;
    if (_classId != null) {
      candidates = studentsProv.byClassSection(_classId!, _sectionId);
    }

    // Default: select everyone in the current filtered group the first
    // time (or whenever the filter changes) so "1-click" really means one
    // tap once the group is chosen.
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
        .map((s) => s.guardianPhone as String)
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Group Call / SMS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _classId,
                  decoration: const InputDecoration(labelText: 'Class'),
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
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'SMS Message',
                    hintText: 'Type the message to send to the whole group…',
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
                      return CheckboxListTile(
                        value: selected,
                        dense: true,
                        title: Text('${s.name} (Roll ${s.roll})'),
                        subtitle: Text(
                          s.guardianPhone.isEmpty
                              ? 'No phone number'
                              : s.guardianPhone,
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.call, color: kAccentGreen),
                          tooltip: 'Call this guardian',
                          onPressed: s.guardianPhone.isEmpty
                              ? null
                              : () => ContactService.makePhoneCall(
                                  context,
                                  s.guardianPhone,
                                ),
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
              padding: const EdgeInsets.all(16),
              child: Row(
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
                      icon: const Icon(Icons.sms_rounded),
                      label: Text('SMS All (${selectedPhones.length})'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: selectedStudents.isEmpty
                          ? null
                          : () => _openCallList(context, selectedStudents),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call List'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCallList(BuildContext context, List<dynamic> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap a guardian to call them one by one',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: students.length,
                itemBuilder: (ctx2, i) {
                  final s = students[i];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(s.name as String),
                    subtitle: Text(
                      (s.guardianPhone as String).isEmpty
                          ? 'No phone number'
                          : s.guardianPhone as String,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: kAccentGreen),
                      onPressed: (s.guardianPhone as String).isEmpty
                          ? null
                          : () => ContactService.makePhoneCall(
                              ctx2,
                              s.guardianPhone as String,
                            ),
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
