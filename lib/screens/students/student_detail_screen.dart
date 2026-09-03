import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/payment.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import '../../services/receipt_service.dart';
import '../../services/contact_service.dart';
import '../../providers/settings_provider.dart';
import '../payments/add_payment_screen.dart';
import '../payments/receipt_preview_screen.dart';
import '../attendance/attendance_screen.dart';
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

    // Map enrolled subjects
    final enrolledSubjectNames = s.subjectIds
        .map((id) => academic.subjectById(id)?.name)
        .whereType<String>()
        .toList();

    final attendanceProv = context.watch<AttendanceProvider>();
    final attendanceStats = attendanceProv.getStudentStats(s.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Save to Phone Contacts',
            onPressed: () => _saveContact(context, s, settings.centerName),
          ),
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
          // Profile Header Card
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  _detailedPhoneRow(
                    context,
                    label: 'Guardian Phone',
                    phone: s.guardianPhone,
                    recipientName: '${s.name} (Guardian: ${s.guardianName})',
                    centerName: settings.centerName,
                  ),
                  if (s.studentPhone != null && s.studentPhone!.isNotEmpty)
                    _detailedPhoneRow(
                      context,
                      label: 'Student Phone',
                      phone: s.studentPhone!,
                      recipientName: s.name,
                      centerName: settings.centerName,
                      isStudentPersonal: true,
                    ),
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

          // Attendance Summary Card
          const SizedBox(height: 12),
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.how_to_reg_rounded, size: 18, color: kPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Attendance (হাজিরা)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              initialClassId: s.classId,
                              initialSectionId: s.sectionId,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Mark Hajira →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _attendanceBadge('Rate', '${attendanceStats.percentage.toStringAsFixed(0)}%', kPrimary),
                      _attendanceBadge('Present', '${attendanceStats.present}', kAccentGreen),
                      _attendanceBadge('Absent', '${attendanceStats.absent}', kAccentRed),
                      _attendanceBadge('Late', '${attendanceStats.late}', kAccentOrange),
                      _attendanceBadge('Leave', '${attendanceStats.leave}', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Enrolled Subjects Card (if any selected)
          if (enrolledSubjectNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.book_outlined, size: 18, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Enrolled Subjects (${enrolledSubjectNames.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: enrolledSubjectNames.map((name) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 14, color: kPrimary),
                              const SizedBox(width: 4),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Quick Multi-Channel Communication Action Box
          const SizedBox(height: 14),
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.forum_outlined, size: 18, color: kPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Direct Communication',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(
                        icon: Icons.call,
                        label: 'Call',
                        color: const Color(0xFF10B981),
                        onTap: () => ContactService.makePhoneCall(
                          context,
                          s.guardianPhone.isNotEmpty ? s.guardianPhone : (s.studentPhone ?? ''),
                        ),
                      ),
                      _actionButton(
                        icon: Icons.sms_rounded,
                        label: 'SMS',
                        color: const Color(0xFF2563EB),
                        onTap: () => ContactService.sendSms(
                          context,
                          s.guardianPhone.isNotEmpty ? s.guardianPhone : (s.studentPhone ?? ''),
                          body: 'Hello from ${settings.centerName}',
                        ),
                      ),
                      _actionButton(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => ContactService.openWhatsApp(
                          context,
                          s.guardianPhone.isNotEmpty ? s.guardianPhone : (s.studentPhone ?? ''),
                          message: 'Hello from ${settings.centerName} regarding student ${s.name}',
                        ),
                      ),
                      _actionButton(
                        icon: Icons.send_rounded,
                        label: 'Telegram',
                        color: const Color(0xFF0088CC),
                        onTap: () => ContactService.openTelegram(
                          context,
                          s.guardianPhone.isNotEmpty ? s.guardianPhone : (s.studentPhone ?? ''),
                          message: 'Hello from ${settings.centerName} regarding student ${s.name}',
                        ),
                      ),
                      _actionButton(
                        icon: Icons.contacts_rounded,
                        label: 'Save',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _saveContact(context, s, settings.centerName),
                      ),
                    ],
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
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
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            _showEditPaymentDialog(context, p, finance);
                          } else if (v == 'delete') {
                            _confirmDeletePayment(context, p.id, finance);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Payment')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete Payment')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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

  void _saveContact(BuildContext context, dynamic student, String centerName) {
    final phone = (student.guardianPhone as String).isNotEmpty
        ? student.guardianPhone as String
        : (student.studentPhone as String? ?? '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available to save.')),
      );
      return;
    }
    ContactService.saveContactToDevice(
      context,
      name: '${student.name} (${student.roll})',
      phone: phone,
      organization: centerName,
      role: 'Student / Guardian',
      note: 'Guardian: ${student.guardianName}',
    );
  }

  Widget _detailedPhoneRow(
    BuildContext context, {
    required String label,
    required String phone,
    required String recipientName,
    required String centerName,
    bool isStudentPersonal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isStudentPersonal ? Icons.phone_android_rounded : Icons.phone_outlined,
            size: 18,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              phone.isEmpty ? '-' : phone,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (phone.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.call, size: 18, color: Color(0xFF10B981)),
              tooltip: 'Call $label',
              visualDensity: VisualDensity.compact,
              onPressed: () => ContactService.makePhoneCall(context, phone),
            ),
            IconButton(
              icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
              tooltip: 'WhatsApp $label',
              visualDensity: VisualDensity.compact,
              onPressed: () => ContactService.openWhatsApp(
                context,
                phone,
                message: 'Hello from $centerName regarding $recipientName',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, size: 18, color: Color(0xFF0088CC)),
              tooltip: 'Telegram $label',
              visualDensity: VisualDensity.compact,
              onPressed: () => ContactService.openTelegram(
                context,
                phone,
                message: 'Hello from $centerName regarding $recipientName',
              ),
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

  Widget _attendanceBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  void _showEditPaymentDialog(BuildContext context, Payment payment, FinanceProvider finance) {
    final amountCtrl = TextEditingController(text: payment.amount.toString());
    final noteCtrl = TextEditingController(text: payment.note ?? '');
    final monthCtrl = TextEditingController(text: payment.monthFor ?? '');
    String method = payment.method;
    DateTime date = payment.date;
    bool receiptGiven = payment.receiptGiven;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date,
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => date = picked);
          }

          return AlertDialog(
            title: const Text('Edit Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: ['Cash', 'bKash', 'Nagad', 'Rocket', 'Bank / Card', 'Online']
                        .map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => method = v ?? method),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: monthCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fee Month (e.g. 2026-03)',
                      hintText: 'YYYY-MM',
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        suffixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      child: Text(fmtDate(date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Receipt Given', style: TextStyle(fontSize: 14)),
                    value: receiptGiven,
                    onChanged: (v) => setState(() => receiptGiven = v),
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
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) return;

                  payment.amount = amount;
                  payment.method = method;
                  payment.monthFor = monthCtrl.text.trim().isEmpty ? null : monthCtrl.text.trim();
                  payment.date = date;
                  payment.note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                  payment.receiptGiven = receiptGiven;

                  finance.updatePayment(payment);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment updated successfully')),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, String id, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: const Text(
          'Are you sure you want to permanently delete this payment? This will update due and income calculations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              finance.deletePayment(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }
}

