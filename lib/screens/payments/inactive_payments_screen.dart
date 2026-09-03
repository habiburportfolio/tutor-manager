import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import '../../services/receipt_service.dart';
import 'receipt_preview_screen.dart';

class InactivePaymentsScreen extends StatefulWidget {
  const InactivePaymentsScreen({super.key});

  @override
  State<InactivePaymentsScreen> createState() => _InactivePaymentsScreenState();
}

class _InactivePaymentsScreenState extends State<InactivePaymentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final students = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final settings = context.watch<SettingsProvider>();

    // Filter payments for inactive or deleted students
    final inactivePayments = finance.payments.where((p) {
      final s = students.byId(p.studentId);
      final isInactive = s == null || !s.isActive;
      if (!isInactive) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (s?.name ?? 'Deleted Student').toLowerCase();
      final roll = (s?.roll ?? '').toLowerCase();
      final receipt = p.receiptNo.toLowerCase();
      final month = (p.monthFor ?? '').toLowerCase();
      return name.contains(q) || roll.contains(q) || receipt.contains(q) || month.contains(q);
    }).toList();

    final totalInactiveAmount = inactivePayments.fold<double>(
      0.0,
      (sum, p) => sum + p.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inactive Student Income'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Inactive Income',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      fmtMoney(totalInactiveAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, roll, receipt...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inactivePayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No inactive student income found.'
                              : 'No matching records found.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: inactivePayments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = inactivePayments[i];
                      final s = students.byId(p.studentId);
                      final studentName = s?.name ?? 'Removed / Deleted Student';
                      final isDeleted = s == null;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: Icon(
                                      isDeleted ? Icons.person_remove_rounded : Icons.person_off_rounded,
                                      color: Colors.grey.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                studentName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isDeleted ? 'Deleted' : 'Inactive',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (s != null)
                                          Text(
                                            'Roll: ${s.roll} • Guardian: ${s.guardianName}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fmtMoney(p.amount),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: kAccentGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.receiptNo} • ${p.method}${p.monthFor != null ? ' • ${p.monthFor}' : ''}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        fmtDateTime(p.date),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      if (p.note != null && p.note!.isNotEmpty)
                                        Text(
                                          'Note: ${p.note}',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (s != null)
                                        IconButton(
                                          icon: const Icon(Icons.print_outlined, size: 20, color: kPrimary),
                                          tooltip: 'Receipt',
                                          onPressed: () => _printReceipt(
                                            context,
                                            p,
                                            s,
                                            academic,
                                            settings,
                                            finance,
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                        tooltip: 'Edit Payment',
                                        onPressed: () => _showEditPaymentDialog(context, p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: kAccentRed),
                                        tooltip: 'Delete Payment',
                                        onPressed: () => _confirmDeletePayment(context, finance, p.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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

  void _confirmDeletePayment(BuildContext context, FinanceProvider finance, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Record?'),
        content: const Text(
          'Are you sure you want to permanently delete this payment? This will update all income calculations.',
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

  void _showEditPaymentDialog(BuildContext context, Payment payment) {
    final amountCtrl = TextEditingController(text: payment.amount.toString());
    final noteCtrl = TextEditingController(text: payment.note ?? '');
    final monthCtrl = TextEditingController(text: payment.monthFor ?? '');
    String method = payment.method;
    DateTime date = payment.date;
    bool receiptGiven = payment.receiptGiven;
    final finance = context.read<FinanceProvider>();

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
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
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

  Future<void> _printReceipt(
    BuildContext context,
    Payment payment,
    dynamic student,
    AcademicProvider academic,
    SettingsProvider settings,
    FinanceProvider finance,
  ) async {
    final className = academic.classById(student.classId)?.name ?? '-';
    final sectionName = academic.sectionById(student.sectionId)?.name ?? '-';
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
    Navigator.push(
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
  }
}
