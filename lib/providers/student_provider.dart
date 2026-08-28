import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../services/db_service.dart';

class StudentProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Student> _students = [];

  List<Student> get students => List.unmodifiable(_students);

  StudentProvider() {
    _load();
  }

  /// Re-reads all data from Hive boxes. Call after a data restore
  /// (e.g. from a Google Drive backup) so the UI reflects the new data.
  void reload() => _load();

  void _load() {
    final box = DBService.box(DBService.studentsBox);
    _students =
        box.values
            .map((e) => Student.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<Student> addStudent({
    required String name,
    required String roll,
    required String classId,
    required String sectionId,
    required String guardianName,
    required String guardianPhone,
    String? address,
    double monthlyFee = 0,
    String? notes,
    DateTime? admissionDate,
  }) async {
    final s = Student(
      id: _uuid.v4(),
      name: name,
      roll: roll,
      classId: classId,
      sectionId: sectionId,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      address: address,
      monthlyFee: monthlyFee,
      admissionDate: admissionDate ?? DateTime.now(),
      notes: notes,
    );
    await DBService.box(DBService.studentsBox).put(s.id, s.toMap());
    _students.add(s);
    _students.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return s;
  }

  Future<void> updateStudent(Student s) async {
    await DBService.box(DBService.studentsBox).put(s.id, s.toMap());
    final idx = _students.indexWhere((x) => x.id == s.id);
    if (idx != -1) _students[idx] = s;
    notifyListeners();
  }

  Future<void> deleteStudent(String id) async {
    await DBService.box(DBService.studentsBox).delete(id);
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Student? byId(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Student> byClassSection(String classId, [String? sectionId]) {
    return _students
        .where(
          (s) =>
              s.classId == classId &&
              (sectionId == null || s.sectionId == sectionId),
        )
        .toList();
  }

  List<Student> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return students;
    return _students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.roll.toLowerCase().contains(q) ||
              s.guardianPhone.contains(q),
        )
        .toList();
  }

  int get totalActiveStudents => _students.where((s) => s.isActive).length;
}
