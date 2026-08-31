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
    String? studentPhone,
    List<String> subjectIds = const [],
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
      studentPhone: studentPhone,
      subjectIds: subjectIds,
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
              (sectionId == null || sectionId.isEmpty || s.sectionId == sectionId),
        )
        .toList();
  }

  List<Student> search(String query, {String? classId, String? sectionId}) {
    final q = query.trim().toLowerCase();
    return _students.where((s) {
      if (classId != null && classId.isNotEmpty && s.classId != classId) {
        return false;
      }
      if (sectionId != null && sectionId.isNotEmpty && s.sectionId != sectionId) {
        return false;
      }
      if (q.isEmpty) return true;
      final matchName = s.name.toLowerCase().contains(q);
      final matchRoll = s.roll.toLowerCase().contains(q);
      final matchGuardianPhone = s.guardianPhone.contains(q);
      final matchStudentPhone = s.studentPhone?.contains(q) ?? false;
      final matchGuardianName = s.guardianName.toLowerCase().contains(q);
      final matchAddress = s.address?.toLowerCase().contains(q) ?? false;
      return matchName || matchRoll || matchGuardianPhone || matchStudentPhone || matchGuardianName || matchAddress;
    }).toList();
  }

  /// Specialized phone lookup
  List<Student> searchByPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return [];
    return _students.where((s) {
      final gClean = s.guardianPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final sClean = (s.studentPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      return gClean.contains(clean) || sClean.contains(clean);
    }).toList();
  }

  int get totalActiveStudents => _students.where((s) => s.isActive).length;
}

