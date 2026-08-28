import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';
import 'group_contact_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _query = '';
  String? _filterClassId;
  String _sortBy = 'Name (A-Z)';

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final finance = context.watch<FinanceProvider>();

    var list = studentsProv.search(_query);
    if (_filterClassId != null) {
      list = list.where((s) => s.classId == _filterClassId).toList();
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Name (A-Z)', child: Text('Name', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Roll Number', child: Text('Roll', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Admission Date', child: Text('Date', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v ?? 'Name (A-Z)'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(
                  'All',
                  _filterClassId == null,
                  () => setState(() => _filterClassId = null),
                ),
                ...academic.classes.map(
                  (c) => _chip(
                    c.name,
                    _filterClassId == c.id,
                    () => setState(() => _filterClassId = c.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No students found.'))
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
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withValues(alpha: 0.15),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0] : '?',
                              style: const TextStyle(color: kPrimary),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('$cls - $sec  |  Roll: ${s.roll}'),
                          trailing: due > 0
                              ? Chip(
                                  label: Text(
                                    fmtMoney(due),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: kAccentRed.withValues(
                                    alpha: 0.12,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: kAccentRed,
                                  ),
                                )
                              : Chip(
                                  label: const Text(
                                    'Paid',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: kAccentGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: kAccentGreen,
                                  ),
                                ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailScreen(studentId: s.id),
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
