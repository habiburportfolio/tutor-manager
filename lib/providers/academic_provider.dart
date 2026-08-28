import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/school_class.dart';
import '../models/section.dart';
import '../models/subject.dart';
import '../services/db_service.dart';

/// Manages Classes, Sections and Subjects.
class AcademicProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<Subject> _subjects = [];

  List<SchoolClass> get classes => List.unmodifiable(_classes);
  List<Section> get sections => List.unmodifiable(_sections);
  List<Subject> get subjects => List.unmodifiable(_subjects);

  AcademicProvider() {
    _load();
  }

  /// Re-reads all data from Hive boxes. Call after a data restore
  /// (e.g. from a Google Drive backup) so the UI reflects the new data.
  void reload() => _load();

  void _load() {
    final cBox = DBService.box(DBService.classesBox);
    final sBox = DBService.box(DBService.sectionsBox);
    final subBox = DBService.box(DBService.subjectsBox);

    _classes =
        cBox.values
            .map((e) => SchoolClass.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    _sections =
        sBox.values
            .map((e) => Section.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    _subjects =
        subBox.values
            .map((e) => Subject.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    notifyListeners();
  }

  // ---------------- Classes ----------------
  Future<SchoolClass> addClass(String name, double defaultFee) async {
    final c = SchoolClass(
      id: _uuid.v4(),
      name: name,
      defaultFee: defaultFee,
      createdAt: DateTime.now(),
    );
    await DBService.box(DBService.classesBox).put(c.id, c.toMap());
    _classes.add(c);
    _classes.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return c;
  }

  Future<void> updateClass(SchoolClass c) async {
    await DBService.box(DBService.classesBox).put(c.id, c.toMap());
    final idx = _classes.indexWhere((x) => x.id == c.id);
    if (idx != -1) _classes[idx] = c;
    notifyListeners();
  }

  Future<void> deleteClass(String id) async {
    await DBService.box(DBService.classesBox).delete(id);
    _classes.removeWhere((c) => c.id == id);
    // cascade delete sections & subjects of this class
    final relatedSections = _sections.where((s) => s.classId == id).toList();
    for (final s in relatedSections) {
      await DBService.box(DBService.sectionsBox).delete(s.id);
    }
    _sections.removeWhere((s) => s.classId == id);

    final relatedSubjects = _subjects.where((s) => s.classId == id).toList();
    for (final s in relatedSubjects) {
      await DBService.box(DBService.subjectsBox).delete(s.id);
    }
    _subjects.removeWhere((s) => s.classId == id);
    notifyListeners();
  }

  // ---------------- Sections ----------------
  Future<Section> addSection(String classId, String name) async {
    final s = Section(
      id: _uuid.v4(),
      classId: classId,
      name: name,
      createdAt: DateTime.now(),
    );
    await DBService.box(DBService.sectionsBox).put(s.id, s.toMap());
    _sections.add(s);
    notifyListeners();
    return s;
  }

  Future<void> deleteSection(String id) async {
    await DBService.box(DBService.sectionsBox).delete(id);
    _sections.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<Section> sectionsForClass(String classId) =>
      _sections.where((s) => s.classId == classId).toList();

  // ---------------- Subjects ----------------
  Future<Subject> addSubject(String classId, String name) async {
    final sub = Subject(
      id: _uuid.v4(),
      classId: classId,
      name: name,
      createdAt: DateTime.now(),
    );
    await DBService.box(DBService.subjectsBox).put(sub.id, sub.toMap());
    _subjects.add(sub);
    notifyListeners();
    return sub;
  }

  Future<void> deleteSubject(String id) async {
    await DBService.box(DBService.subjectsBox).delete(id);
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<Subject> subjectsForClass(String classId) =>
      _subjects.where((s) => s.classId == classId).toList();

  SchoolClass? classById(String id) {
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Section? sectionById(String id) {
    try {
      return _sections.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Subject? subjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
