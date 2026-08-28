/// An expense (outgoing money) record for the coaching center.
class Expense {
  String id;
  String title;
  double amount;
  DateTime date;
  String category; // Rent, Salary, Utility, Stationery, Other
  String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.category = 'Other',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'note': note,
  };

  factory Expense.fromMap(Map map) => Expense(
    id: map['id'] as String,
    title: map['title']?.toString() ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    category: map['category']?.toString() ?? 'Other',
    note: map['note']?.toString(),
  );
}
