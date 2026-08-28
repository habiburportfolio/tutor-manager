class Section {
  String id;
  String classId;
  String name; // e.g. "A", "B", "Section 1"
  DateTime createdAt;

  Section({
    required this.id,
    required this.classId,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'classId': classId,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Section.fromMap(Map map) => Section(
    id: map['id'] as String,
    classId: map['classId'] as String,
    name: map['name'] as String,
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
