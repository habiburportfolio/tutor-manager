import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/contact_service.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';
import 'group_contact_screen.dart';
import '../../widgets/app_logo.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _query = '';
  String? _filterClassId;
  String? _filterSectionId;
  String _sortBy = 'Name (A-Z)';

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final finance = context.watch<FinanceProvider>();
    final settings = context.watch<SettingsProvider>();

    var list = studentsProv.search(
      _query,
      classId: _filterClassId,
      sectionId: _filterSectionId,
    ).toList();

    if (_sortBy == 'Name (A-Z)') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'Roll Number') {
      list.sort((a, b) {
        final aRoll = int.tryParse(a.roll) ?? 999999;
        final bRoll = int.tryParse(b.roll) ?? 999999;
        return aRoll.compareTo(bRoll);
      });
    } else if (_sortBy == 'Admission Date') {
      list.sort((a, b) => a.admissionDate.compareTo(b.admissionDate));
    }

    final availableSections = _filterClassId != null
        ? academic.sectionsForClass(_filterClassId!)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            const Text('Students'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded),
            tooltip: 'Search by Mobile Number',
            onPressed: () => _openPhoneSearchModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.groups_rounded),
            tooltip: 'Group Call / SMS',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupContactScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
        ),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search name, roll, phone...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _query = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Name (A-Z)', child: Text('Name', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Roll Number', child: Text('Roll', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Admission Date', child: Text('Date', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v ?? 'Name (A-Z)'),
                  ),
                ),
              ],
            ),
          ),

          // Class Filter Bar
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(
                  'All Classes',
                  _filterClassId == null,
                  () => setState(() {
                    _filterClassId = null;
                    _filterSectionId = null;
                  }),
                ),
                ...academic.classes.map(
                  (c) => _chip(
                    c.name,
                    _filterClassId == c.id,
                    () => setState(() {
                      _filterClassId = c.id;
                      _filterSectionId = null;
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Section Filter Bar (Appears when Class or All is selected)
          if (availableSections.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _subChip(
                    'All Sections',
                    _filterSectionId == null,
                    () => setState(() => _filterSectionId = null),
                  ),
                  ...availableSections.map(
                    (s) => _subChip(
                      'Section ${s.name}',
                      _filterSectionId == s.id,
                      () => setState(() => _filterSectionId = s.id),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'No students match your filter.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      final cls = academic.classById(s.classId)?.name ?? '';
                      final sec = academic.sectionById(s.sectionId)?.name ?? '';
                      final paid = finance.totalPaidByStudent(s.id);
                      final due = DueCalculator.due(s, paid);
                      final phone = s.guardianPhone.isNotEmpty ? s.guardianPhone : (s.studentPhone ?? '');

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withValues(alpha: 0.15),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0] : '?',
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (due > 0)
                                Chip(
                                  label: Text(
                                    fmtMoney(due),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: kAccentRed.withValues(alpha: 0.12),
                                  labelStyle: const TextStyle(color: kAccentRed),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                )
                              else
                                Chip(
                                  label: const Text(
                                    'Paid',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: kAccentGreen.withValues(alpha: 0.12),
                                  labelStyle: const TextStyle(color: kAccentGreen),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$cls - Section $sec  |  Roll: ${s.roll}'),
                              if (phone.isNotEmpty)
                                Text(
                                  '📞 $phone',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (phone.isNotEmpty) ...[
                                IconButton(
                                  icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                  tooltip: 'WhatsApp',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => ContactService.openWhatsApp(
                                    context,
                                    phone,
                                    message: 'Hello from ${settings.centerName} regarding ${s.name}',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                                  tooltip: 'Call',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => ContactService.makePhoneCall(context, phone),
                                ),
                              ],
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(studentId: s.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openPhoneSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _PhoneSearchBottomSheet(),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _subChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: selected ? kPrimary : null)),
        selected: selected,
        selectedColor: kPrimary.withValues(alpha: 0.15),
        checkmarkColor: kPrimary,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _PhoneSearchBottomSheet extends StatefulWidget {
  const _PhoneSearchBottomSheet();

  @override
  State<_PhoneSearchBottomSheet> createState() => _PhoneSearchBottomSheetState();
}

class _PhoneSearchBottomSheetState extends State<_PhoneSearchBottomSheet> {
  final _phoneCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final settings = context.watch<SettingsProvider>();

    final results = _searchQuery.isEmpty
        ? []
        : studentsProv.searchByPhone(_searchQuery);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.phone_in_talk_rounded, color: kPrimary),
                SizedBox(width: 8),
                Text(
                  'Search Student by Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter mobile number (e.g. 017...)',
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _phoneCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(
                      child: Text(
                        'Type a phone number to search students...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : results.isEmpty
                      ? Center(
                          child: Text(
                            'No student found with phone containing "$_searchQuery"',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = results[i];
                            final cls = academic.classById(s.classId)?.name ?? '';
                            final sec = academic.sectionById(s.sectionId)?.name ?? '';
                            final phone = s.guardianPhone.isNotEmpty
                                ? s.guardianPhone
                                : (s.studentPhone ?? '');

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kPrimary.withValues(alpha: 0.15),
                                child: Text(s.name.isNotEmpty ? s.name[0] : '?'),
                              ),
                              title: Text('${s.name} (Roll ${s.roll})'),
                              subtitle: Text('$cls - Section $sec\nGuardian: ${s.guardianPhone}${s.studentPhone != null ? " | Student: ${s.studentPhone}" : ""}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                                    onPressed: () => ContactService.makePhoneCall(context, phone),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                    onPressed: () => ContactService.openWhatsApp(
                                      context,
                                      phone,
                                      message: 'Hello from ${settings.centerName} regarding ${s.name}',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF8B5CF6), size: 20),
                                    tooltip: 'Save to Contacts',
                                    onPressed: () => ContactService.saveContactToDevice(
                                      context,
                                      name: '${s.name} (${s.roll})',
                                      phone: phone,
                                      organization: settings.centerName,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailScreen(studentId: s.id),
                                  ),
                                );
                              },
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

