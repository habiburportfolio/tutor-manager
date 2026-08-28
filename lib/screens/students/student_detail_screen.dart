import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import '../../services/receipt_service.dart';
import '../../services/contact_service.dart';
import '../../providers/settings_provider.dart';
import '../payments/add_payment_screen.dart';
import '../payments/receipt_preview_screen.dart';
import 'add_edit_student_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final finance = context.watch<FinanceProvider>();
    final settings = context.watch<SettingsProvider>();
    final quickCallSmsEnabled = settings.enableQuickCallSms;

    final s = studentsProv.byId(studentId);
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final cls = academic.classById(s.classId)?.name ?? '-';
    final sec = academic.sectionById(s.sectionId)?.name ?? '-';
    final payments = finance.paymentsForStudent(s.id);
    final totalPaid = finance.totalPaidByStudent(s.id);
    final expected = DueCalculator.expectedTotal(s);
    final due = DueCalculator.due(s, totalPaid);
    final advance = DueCalculator.advance(s, totalPaid);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          if (quickCallSmsEnabled) ...[
            IconButton(
              icon: const Icon(Icons.call_outlined),
              tooltip: 'Call Guardian',
              onPressed: s.guardianPhone.isEmpty
                  ? null
                  : () =>
                        ContactService.makePhoneCall(context, s.guardianPhone),
            ),
            IconButton(
              icon: const Icon(Icons.sms_outlined),
              tooltip: 'Send SMS',
              onPressed: s.guardianPhone.isEmpty
                  ? null
                  : () => ContactService.sendSms(context, s.guardianPhone),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Student',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditStudentScreen(existing: s),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kAccentRed),
            tooltip: 'Delete Student',
            onPressed: () => _confirmDeleteStudent(context, s),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPaymentScreen(preselectedStudentId: s.id),
          ),
        ),
        icon: const Icon(Icons.payments_rounded),
        label: const Text('Collect Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: kPrimary.withValues(alpha: 0.15),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0] : '?',
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$cls - Section $sec  |  Roll: ${s.roll}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(Icons.person_outline, 'Guardian', s.guardianName),
                  _phoneRow(context, s.guardianPhone, quickCallSmsEnabled),
                  if (s.address != null && s.address!.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, 'Address', s.address!),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Admission',
                    fmtDate(s.admissionDate),
                  ),
                  _infoRow(
                    Icons.attach_money_outlined,
                    'Monthly Fee',
                    fmtMoney(s.monthlyFee),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _moneyCard(
                  'Total Expected',
                  fmtMoney(expected),
                  kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _moneyCard(
                  'Total Paid',
                  fmtMoney(totalPaid),
                  kAccentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _moneyCard(
                  'Due',
                  fmtMoney(due),
                  due > 0 ? kAccentRed : Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _moneyCard(
                  'Advance',
                  fmtMoney(advance),
                  advance > 0 ? kAccentGreen : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No payments recorded yet.')),
            )
          else
            ...payments.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    p.receiptGiven
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: p.receiptGiven ? kAccentGreen : kAccentRed,
                    size: 30,
                  ),
                  title: Text(
                    fmtMoney(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.receiptNo}\n${fmtDateTime(p.date)} • ${p.method}${p.monthFor != null ? ' • ${p.monthFor}' : ''}\n'
                    '${p.receiptGiven ? "Receipt given" : "Receipt NOT given yet"}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.print_outlined, color: kPrimary),
                    tooltip: 'Print / Give Receipt',
                    onPressed: () => _printOrGiveReceipt(
                      context,
                      p,
                      s,
                      cls,
                      sec,
                      finance,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _printOrGiveReceipt(
    BuildContext context,
    dynamic payment,
    dynamic student,
    String className,
    String sectionName,
    FinanceProvider finance,
  ) async {
    final settings = context.read<SettingsProvider>();
    final paidAfter = finance.totalPaidByStudent(student.id);
    final dueAfter = DueCalculator.due(student, paidAfter);

    final pdfBytes = await ReceiptService.buildReceiptPdf(
      payment: payment,
      student: student,
      className: className,
      sectionName: sectionName,
      centerName: settings.centerName,
      centerPhone: settings.centerPhone,
      centerAddress: settings.centerAddress,
      totalDueAfter: dueAfter,
    );

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(
          pdfBytes: pdfBytes,
          fileName: '${payment.receiptNo}.pdf',
          studentPhone: student.guardianPhone,
          studentName: student.name,
        ),
      ),
    );

    if (!payment.receiptGiven) {
      await finance.markReceiptGiven(payment.id, true);
    }
  }

  Widget _phoneRow(BuildContext context, String phone, bool showActions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          const Text('Phone: ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              phone.isEmpty ? '-' : phone,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showActions && phone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.call, size: 20, color: kAccentGreen),
              tooltip: 'Call',
              onPressed: () => ContactService.makePhoneCall(context, phone),
            ),
            IconButton(
              icon: const Icon(Icons.sms, size: 20, color: kPrimary),
              tooltip: 'SMS',
              onPressed: () => ContactService.sendSms(context, phone),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteStudent(BuildContext context, dynamic student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'This will permanently delete "${student.name}" from the records. '
          'Payment history for this student will remain but will no longer '
          'be linked to a visible student. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<StudentProvider>().deleteStudent(student.id);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // go back from detail screen
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
