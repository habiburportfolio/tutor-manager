import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/receipt_service.dart';
import '../../services/payment_gateway_service.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../utils/due_calculator.dart';
import '../../models/student.dart';
import 'receipt_preview_screen.dart';
import 'gateway_checkout_screen.dart';

class AddPaymentScreen extends StatefulWidget {
  final String? preselectedStudentId;
  const AddPaymentScreen({super.key, this.preselectedStudentId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _studentId;
  late String _method;
  String? _monthFor;
  bool _processingOnline = false;
  DateTime _date = DateTime.now();
  bool _giveReceiptNow = true;

  final _methods = const [
    'Cash',
    'bKash',
    'Nagad',
    'Rocket',
    'Bank',
    'Card',
    'SSLCommerz (Online)',
    'bKash (Online)',
    'Nagad (Online)',
  ];

  bool get _isOnlineGateway =>
      _method == 'SSLCommerz (Online)' ||
      _method == 'bKash (Online)' ||
      _method == 'Nagad (Online)';

  @override
  void initState() {
    super.initState();
    _studentId = widget.preselectedStudentId;
    final now = DateTime.now();
    _monthFor = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // Apply user-configured defaults from Settings (General section).
    final settings = context.read<SettingsProvider>();
    _method = _methods.contains(settings.defaultPaymentMethod)
        ? settings.defaultPaymentMethod
        : 'Cash';
    _giveReceiptNow = settings.defaultGiveReceiptNow;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsProv = context.watch<StudentProvider>();
    final academic = context.watch<AcademicProvider>();
    final finance = context.watch<FinanceProvider>();

    Student? student = _studentId != null
        ? studentsProv.byId(_studentId!)
        : null;
    double due = 0;
    if (student != null) {
      final paid = finance.totalPaidByStudent(student.id);
      due = DueCalculator.due(student, paid);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.preselectedStudentId == null)
              DropdownButtonFormField<String>(
                initialValue: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Select Student *',
                ),
                items: studentsProv.students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.name} (${academic.classById(s.classId)?.name ?? ''} - Roll ${s.roll})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _studentId = v),
                validator: (v) => v == null ? 'Select a student' : null,
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: kPrimary),
                      const SizedBox(width: 10),
                      Text(
                        student?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            if (student != null) ...[
              const SizedBox(height: 10),
              Text(
                'Current Due: ${fmtMoney(due)}',
                style: TextStyle(
                  color: due > 0 ? kAccentRed : kAccentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount *'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? 'Cash'),
            ),
            const SizedBox(height: 12),
            // Payment Date field with calendar picker. Defaults to today
            // but can be changed to record a backdated/forward-dated payment.
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date *',
                  suffixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(fmtDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _monthFor,
              decoration: const InputDecoration(
                labelText: 'Month (e.g. 2025-01)',
              ),
              onChanged: (v) => _monthFor = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (!_isOnlineGateway) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _giveReceiptNow,
                onChanged: (v) => setState(() => _giveReceiptNow = v),
                title: const Text('Give money receipt now?'),
                subtitle: Text(
                  _giveReceiptNow
                      ? 'Receipt will be shown/printed immediately'
                      : 'Receipt marked as NOT given yet — you can print it anytime later from Student Details',
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processingOnline ? null : () => _submit(context),
              icon: _processingOnline
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isOnlineGateway
                    ? 'Initiate Online Payment'
                    : 'Save Payment & Generate Receipt',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_studentId == null) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final finance = context.read<FinanceProvider>();
    final studentsProv = context.read<StudentProvider>();
    final settings = context.read<SettingsProvider>();
    final academic = context.read<AcademicProvider>();

    final student = studentsProv.byId(_studentId!)!;
    bool receiptGiven = _giveReceiptNow;

    if (_isOnlineGateway) {
      setState(() => _processingOnline = true);
      final gateway = PaymentGatewayService(settings);
      final orderId = 'TM${DateTime.now().millisecondsSinceEpoch}';
      final result = await gateway.initiatePayment(
        method: _method,
        studentName: student.name,
        phone: student.guardianPhone,
        amount: amount,
        orderId: orderId,
      );
      setState(() => _processingOnline = false);

      if (!result.success || result.checkoutUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: kAccentRed,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => GatewayCheckoutScreen(
            checkoutUrl: result.checkoutUrl!,
            gatewayName: _method,
          ),
        ),
      );
      if (paid != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Online payment was not completed.'),
              backgroundColor: kAccentRed,
            ),
          );
        }
        return;
      }
      // Online gateway payments always produce an immediate digital
      // confirmation, so the receipt is considered given right away.
      receiptGiven = true;
    }

    final payment = await finance.addPayment(
      studentId: _studentId!,
      amount: amount,
      method: _method,
      monthFor: _monthFor,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _date,
      receiptGiven: receiptGiven,
    );

    final paidAfter = finance.totalPaidByStudent(_studentId!);
    final dueAfter = DueCalculator.due(student, paidAfter);

    final pdfBytes = await ReceiptService.buildReceiptPdf(
      payment: payment,
      student: student,
      className: academic.classById(student.classId)?.name ?? '',
      sectionName: academic.sectionById(student.sectionId)?.name ?? '',
      centerName: settings.centerName,
      centerPhone: settings.centerPhone,
      centerAddress: settings.centerAddress,
      totalDueAfter: dueAfter,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
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
