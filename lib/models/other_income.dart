/// An other income (non-student/general income) record for the coaching center.
class OtherIncome {
  String id;
  String title;
  double amount;
  DateTime date;
  String category; // Admission Fee, Book / Sheet, Exam Fee, Batch Fee, Donation, Other
  String method; // Cash, bKash, Nagad, Rocket, Card, Online
  String? note;
  String receiptNo;

  OtherIncome({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.category = 'Other',
    this.method = 'Cash',
    this.note,
    required this.receiptNo,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'method': method,
    'note': note,
    'receiptNo': receiptNo,
  };

  factory OtherIncome.fromMap(Map map) => OtherIncome(
    id: map['id'] as String,
    title: map['title']?.toString() ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    category: map['category']?.toString() ?? 'Other',
    method: map['method']?.toString() ?? 'Cash',
    note: map['note']?.toString(),
    receiptNo: map['receiptNo']?.toString() ?? '',
  );
}
