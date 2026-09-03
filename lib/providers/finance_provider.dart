import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../models/other_income.dart';
import '../services/db_service.dart';

enum ReportRange { daily, weekly, monthly, yearly }

class FinanceProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Payment> _payments = [];
  List<Expense> _expenses = [];
  List<OtherIncome> _otherIncomes = [];

  List<Payment> get payments => List.unmodifiable(_payments);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<OtherIncome> get otherIncomes => List.unmodifiable(_otherIncomes);

  FinanceProvider() {
    _load();
  }

  /// Re-reads all data from Hive boxes. Call after a data restore
  /// (e.g. from a Google Drive backup) so the UI reflects the new data.
  void reload() => _load();

  void _load() {
    final pBox = DBService.box(DBService.paymentsBox);
    final eBox = DBService.box(DBService.expensesBox);
    final oBox = DBService.box(DBService.otherIncomeBox);

    _payments =
        pBox.values
            .map((e) => Payment.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    _expenses =
        eBox.values
            .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    _otherIncomes =
        oBox.values
            .map((e) => OtherIncome.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  String _generateReceiptNo([String prefix = 'RCT']) {
    final now = DateTime.now();
    final count = _payments.length + _otherIncomes.length + 1;
    return '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}-${count.toString().padLeft(4, '0')}';
  }

  // ---------------- Payments (Student Income) ----------------
  Future<Payment> addPayment({
    required String studentId,
    required double amount,
    String method = 'Cash',
    String? monthFor,
    String? note,
    DateTime? date,
    bool receiptGiven = true,
  }) async {
    final p = Payment(
      id: _uuid.v4(),
      studentId: studentId,
      amount: amount,
      date: date ?? DateTime.now(),
      method: method,
      monthFor: monthFor,
      note: note,
      receiptNo: _generateReceiptNo('RCT'),
      receiptGiven: receiptGiven,
    );
    await DBService.box(DBService.paymentsBox).put(p.id, p.toMap());
    _payments.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<void> updatePayment(Payment p) async {
    await DBService.box(DBService.paymentsBox).put(p.id, p.toMap());
    final idx = _payments.indexWhere((x) => x.id == p.id);
    if (idx != -1) _payments[idx] = p;
    _payments.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deletePayment(String id) async {
    await DBService.box(DBService.paymentsBox).delete(id);
    _payments.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Marks whether the printed money receipt has been physically given to
  /// the guardian/student for the given payment.
  Future<void> markReceiptGiven(String paymentId, bool given) async {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    _payments[idx].receiptGiven = given;
    await DBService.box(
      DBService.paymentsBox,
    ).put(paymentId, _payments[idx].toMap());
    notifyListeners();
  }

  Payment? paymentById(String id) {
    try {
      return _payments.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Payment> paymentsForStudent(String studentId) =>
      _payments.where((p) => p.studentId == studentId).toList();

  double totalPaidByStudent(String studentId) =>
      paymentsForStudent(studentId).fold(0.0, (sum, p) => sum + p.amount);

  // ---------------- Other Incomes (Miscellaneous Income) ----------------
  Future<OtherIncome> addOtherIncome({
    required String title,
    required double amount,
    String category = 'Other',
    String method = 'Cash',
    String? note,
    DateTime? date,
  }) async {
    final o = OtherIncome(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      date: date ?? DateTime.now(),
      category: category,
      method: method,
      note: note,
      receiptNo: _generateReceiptNo('OTH'),
    );
    await DBService.box(DBService.otherIncomeBox).put(o.id, o.toMap());
    _otherIncomes.insert(0, o);
    notifyListeners();
    return o;
  }

  Future<void> updateOtherIncome(OtherIncome o) async {
    await DBService.box(DBService.otherIncomeBox).put(o.id, o.toMap());
    final idx = _otherIncomes.indexWhere((x) => x.id == o.id);
    if (idx != -1) _otherIncomes[idx] = o;
    _otherIncomes.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteOtherIncome(String id) async {
    await DBService.box(DBService.otherIncomeBox).delete(id);
    _otherIncomes.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  OtherIncome? otherIncomeById(String id) {
    try {
      return _otherIncomes.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------------- Expenses ----------------
  Future<Expense> addExpense({
    required String title,
    required double amount,
    String category = 'Other',
    String? note,
    DateTime? date,
  }) async {
    final e = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      date: date ?? DateTime.now(),
      category: category,
      note: note,
    );
    await DBService.box(DBService.expensesBox).put(e.id, e.toMap());
    _expenses.insert(0, e);
    notifyListeners();
    return e;
  }

  Future<void> updateExpense(Expense e) async {
    await DBService.box(DBService.expensesBox).put(e.id, e.toMap());
    final idx = _expenses.indexWhere((x) => x.id == e.id);
    if (idx != -1) _expenses[idx] = e;
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await DBService.box(DBService.expensesBox).delete(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---------------- Aggregation helpers ----------------
  bool _inRange(DateTime d, DateTime start, DateTime end) =>
      !d.isBefore(start) && d.isBefore(end);

  DateTimeRange rangeFor(ReportRange range, [DateTime? anchor]) {
    final a = anchor ?? DateTime.now();
    switch (range) {
      case ReportRange.daily:
        final start = DateTime(a.year, a.month, a.day);
        return DateTimeRange(start, start.add(const Duration(days: 1)));
      case ReportRange.weekly:
        final startOfWeek = a.subtract(Duration(days: a.weekday - 1));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return DateTimeRange(start, start.add(const Duration(days: 7)));
      case ReportRange.monthly:
        final start = DateTime(a.year, a.month, 1);
        final end = DateTime(a.year, a.month + 1, 1);
        return DateTimeRange(start, end);
      case ReportRange.yearly:
        final start = DateTime(a.year, 1, 1);
        final end = DateTime(a.year + 1, 1, 1);
        return DateTimeRange(start, end);
    }
  }

  double studentIncomeInRange(DateTime start, DateTime end) => _payments
      .where((p) => _inRange(p.date, start, end))
      .fold(0.0, (sum, p) => sum + p.amount);

  double otherIncomeInRange(DateTime start, DateTime end) => _otherIncomes
      .where((o) => _inRange(o.date, start, end))
      .fold(0.0, (sum, o) => sum + o.amount);

  double incomeInRange(DateTime start, DateTime end) =>
      studentIncomeInRange(start, end) + otherIncomeInRange(start, end);

  double expenseInRange(DateTime start, DateTime end) => _expenses
      .where((e) => _inRange(e.date, start, end))
      .fold(0.0, (sum, e) => sum + e.amount);

  double incomeFor(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return incomeInRange(r.start, r.end);
  }

  double studentIncomeFor(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return studentIncomeInRange(r.start, r.end);
  }

  double otherIncomeFor(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return otherIncomeInRange(r.start, r.end);
  }

  double expenseFor(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return expenseInRange(r.start, r.end);
  }

  double profitFor(ReportRange range, [DateTime? anchor]) =>
      incomeFor(range, anchor) - expenseFor(range, anchor);

  List<Payment> paymentsForRange(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return _payments.where((p) => _inRange(p.date, r.start, r.end)).toList();
  }

  List<OtherIncome> otherIncomesForRange(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    return _otherIncomes.where((o) => _inRange(o.date, r.start, r.end)).toList();
  }

  List<Expense> expensesForRange(ReportRange range, [DateTime? anchor, String? category]) {
    final r = rangeFor(range, anchor);
    return _expenses.where((e) {
      final matchesRange = _inRange(e.date, r.start, r.end);
      if (category != null && category.isNotEmpty) {
        return matchesRange && e.category.toLowerCase() == category.toLowerCase();
      }
      return matchesRange;
    }).toList();
  }

  Map<String, double> categoryExpenseBreakdown(ReportRange range, [DateTime? anchor]) {
    final r = rangeFor(range, anchor);
    final map = <String, double>{};
    for (final e in _expenses) {
      if (_inRange(e.date, r.start, r.end)) {
        map[e.category] = (map[e.category] ?? 0.0) + e.amount;
      }
    }
    return map;
  }

  /// Returns list of (label, income, expense) for the last [count] periods
  List<PeriodStat> trend(ReportRange range, int count) {
    final now = DateTime.now();
    final List<PeriodStat> result = [];
    for (int i = count - 1; i >= 0; i--) {
      DateTime anchor;
      String label;
      switch (range) {
        case ReportRange.daily:
          anchor = now.subtract(Duration(days: i));
          label = '${anchor.day}/${anchor.month}';
          break;
        case ReportRange.weekly:
          anchor = now.subtract(Duration(days: i * 7));
          final r = rangeFor(ReportRange.weekly, anchor);
          label = '${r.start.day}/${r.start.month}';
          break;
        case ReportRange.monthly:
          anchor = DateTime(now.year, now.month - i, 1);
          label = _monthShort(anchor.month);
          break;
        case ReportRange.yearly:
          anchor = DateTime(now.year - i, 1, 1);
          label = '${anchor.year}';
          break;
      }
      final r = rangeFor(range, anchor);
      result.add(
        PeriodStat(
          label: label,
          income: incomeInRange(r.start, r.end),
          expense: expenseInRange(r.start, r.end),
        ),
      );
    }
    return result;
  }

  String _monthShort(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final idx = ((month - 1) % 12 + 12) % 12;
    return names[idx];
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange(this.start, this.end);
}

class PeriodStat {
  final String label;
  final double income;
  final double expense;
  PeriodStat({
    required this.label,
    required this.income,
    required this.expense,
  });
}
