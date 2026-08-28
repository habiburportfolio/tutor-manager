import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../utils/due_calculator.dart';
import '../students/student_detail_screen.dart';

class StudentDuesList extends StatelessWidget {
  const StudentDuesList({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final students = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();

    final withDue =
        students.students
            .map((s) {
              final paid = finance.totalPaidByStudent(s.id);
              final due = DueCalculator.due(s, paid);
              return (s, due);
            })
            .where((e) => e.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(title: const Text('Students with Due')),
      body: withDue.isEmpty
          ? const Center(child: Text('🎉 No dues! Everyone has paid.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: withDue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = withDue[i].$1;
                final due = withDue[i].$2;
                final cls = academic.classById(s.classId)?.name ?? '';
                final sec = academic.sectionById(s.sectionId)?.name ?? '';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimary.withValues(alpha: 0.15),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0] : '?',
                        style: const TextStyle(color: kPrimary),
                      ),
                    ),
                    title: Text(s.name),
                    subtitle: Text('$cls - $sec  |  Roll: ${s.roll}'),
                    trailing: Text(
                      fmtMoney(due),
                      style: const TextStyle(
                        color: kAccentRed,
                        fontWeight: FontWeight.bold,
                      ),
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
    );
  }
}
