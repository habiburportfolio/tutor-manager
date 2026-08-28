/// A payment (income) record made by a student/guardian.
class Payment {
  String id;
  String studentId;
  double amount;
  DateTime date;
  String method; // Cash, bKash, Nagad, Rocket, Card, Online
  String? monthFor; // e.g. "2025-01" which month's fee this covers
  String? note;
  String receiptNo;

  /// Whether the printed money receipt has already been physically given
  /// to the guardian/student. If false, the app shows a ✗ (cross) marker
  /// on the payment history and allows printing/giving it later at any time.
  bool receiptGiven;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.date,
    this.method = 'Cash',
    this.monthFor,
    this.note,
    required this.receiptNo,
    this.receiptGiven = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'amount': amount,
    'date': date.toIso8601String(),
    'method': method,
    'monthFor': monthFor,
    'note': note,
    'receiptNo': receiptNo,
    'receiptGiven': receiptGiven,
  };

  factory Payment.fromMap(Map map) => Payment(
    id: map['id'] as String,
    studentId: map['studentId'] as String,
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    method: map['method']?.toString() ?? 'Cash',
    monthFor: map['monthFor']?.toString(),
    note: map['note']?.toString(),
    receiptNo: map['receiptNo']?.toString() ?? '',
    // Backward-compatible: payments created before this field existed
    // are treated as "receipt given" (matches the old immediate-print flow).
    receiptGiven: map['receiptGiven'] as bool? ?? true,
  );
}
