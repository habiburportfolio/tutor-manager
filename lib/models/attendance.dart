/// A student attendance record.
class AttendanceRecord {
  String id;
  DateTime date; // Normalized to YYYY-MM-DD
  String studentId;
  String classId;
  String sectionId;
  String status; // Present, Absent, Late, Leave
  String? note;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.studentId,
    required this.classId,
    required this.sectionId,
    this.status = 'Present',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'studentId': studentId,
    'classId': classId,
    'sectionId': sectionId,
    'status': status,
    'note': note,
  };

  factory AttendanceRecord.fromMap(Map map) => AttendanceRecord(
    id: map['id'] as String,
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    studentId: map['studentId'] as String? ?? '',
    classId: map['classId'] as String? ?? '',
    sectionId: map['sectionId'] as String? ?? '',
    status: map['status']?.toString() ?? 'Present',
    note: map['note']?.toString(),
  );
}
