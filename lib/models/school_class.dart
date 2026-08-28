class SchoolClass {
  String id;
  String name; // e.g. "Class 5"
  double defaultFee; // default monthly fee for this class
  DateTime createdAt;

  SchoolClass({
    required this.id,
    required this.name,
    this.defaultFee = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'defaultFee': defaultFee,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SchoolClass.fromMap(Map map) => SchoolClass(
    id: map['id'] as String,
    name: map['name'] as String,
    defaultFee: (map['defaultFee'] as num?)?.toDouble() ?? 0,
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
