/// A homework assignment sent to one or more students.
class Homework {
  String id;
  String classId;
  String sectionId;
  String subjectId;
  String title;
  String description;
  DateTime date;
  DateTime? dueDate;
  List<String> studentIds; // recipients
  List<String> attachmentPaths; // local file paths (image/pdf/doc)
  List<String> sentVia; // ["SMS", "WhatsApp", "Messenger"]

  Homework({
    required this.id,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.date,
    this.dueDate,
    this.studentIds = const [],
    this.attachmentPaths = const [],
    this.sentVia = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'classId': classId,
    'sectionId': sectionId,
    'subjectId': subjectId,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'studentIds': studentIds,
    'attachmentPaths': attachmentPaths,
    'sentVia': sentVia,
  };

  factory Homework.fromMap(Map map) => Homework(
    id: map['id'] as String,
    classId: map['classId']?.toString() ?? '',
    sectionId: map['sectionId']?.toString() ?? '',
    subjectId: map['subjectId']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    dueDate: map['dueDate'] != null
        ? DateTime.tryParse(map['dueDate'].toString())
        : null,
    studentIds: (map['studentIds'] as List?)?.cast<String>() ?? [],
    attachmentPaths: (map['attachmentPaths'] as List?)?.cast<String>() ?? [],
    sentVia: (map['sentVia'] as List?)?.cast<String>() ?? [],
  );
}
