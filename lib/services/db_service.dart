import 'package:hive_flutter/hive_flutter.dart';

/// Central Hive database service.
/// Uses plain Map-based boxes (no code generation) for simplicity & speed.
/// This is a "local-first" data layer — designed so a cloud sync adapter
/// (e.g. Supabase) can be added later without changing screen code, by
/// swapping the repository implementations that read/write these boxes.
class DBService {
  static const String studentsBox = 'students_box';
  static const String classesBox = 'classes_box';
  static const String sectionsBox = 'sections_box';
  static const String subjectsBox = 'subjects_box';
  static const String paymentsBox = 'payments_box';
  static const String expensesBox = 'expenses_box';
  static const String homeworkBox = 'homework_box';
  static const String settingsBox = 'settings_box';
  static const String meetingsBox = 'meetings_box';

  /// All box names known to the app - used by BackupService to export/
  /// import every piece of stored data generically.
  static const List<String> allBoxNames = [
    studentsBox,
    classesBox,
    sectionsBox,
    subjectsBox,
    paymentsBox,
    expensesBox,
    homeworkBox,
    settingsBox,
    meetingsBox,
  ];

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(studentsBox),
      Hive.openBox(classesBox),
      Hive.openBox(sectionsBox),
      Hive.openBox(subjectsBox),
      Hive.openBox(paymentsBox),
      Hive.openBox(expensesBox),
      Hive.openBox(homeworkBox),
      Hive.openBox(settingsBox),
      Hive.openBox(meetingsBox),
    ]);
  }

  static Box box(String name) => Hive.box(name);
}
