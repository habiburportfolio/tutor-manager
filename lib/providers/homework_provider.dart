import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/homework.dart';
import '../services/db_service.dart';

class HomeworkProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Homework> _homeworks = [];

  List<Homework> get homeworks => List.unmodifiable(_homeworks);

  HomeworkProvider() {
    _load();
  }

  /// Re-reads all data from Hive boxes. Call after a data restore
  /// (e.g. from a Google Drive backup) so the UI reflects the new data.
  void reload() => _load();

  void _load() {
    final box = DBService.box(DBService.homeworkBox);
    _homeworks =
        box.values
            .map((e) => Homework.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<Homework> addHomework({
    required String classId,
    required String sectionId,
    required String subjectId,
    required String title,
    required String description,
    DateTime? dueDate,
    List<String> studentIds = const [],
    List<String> attachmentPaths = const [],
    List<String> sentVia = const [],
  }) async {
    final h = Homework(
      id: _uuid.v4(),
      classId: classId,
      sectionId: sectionId,
      subjectId: subjectId,
      title: title,
      description: description,
      date: DateTime.now(),
      dueDate: dueDate,
      studentIds: studentIds,
      attachmentPaths: attachmentPaths,
      sentVia: sentVia,
    );
    await DBService.box(DBService.homeworkBox).put(h.id, h.toMap());
    _homeworks.insert(0, h);
    notifyListeners();
    return h;
  }

  Future<void> deleteHomework(String id) async {
    await DBService.box(DBService.homeworkBox).delete(id);
    _homeworks.removeWhere((h) => h.id == id);
    notifyListeners();
  }
}
