import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/meeting.dart';
import '../services/db_service.dart';

class MeetingProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Meeting> _meetings = [];

  List<Meeting> get meetings => List.unmodifiable(_meetings);

  MeetingProvider() {
    _load();
  }

  /// Re-reads all data from Hive boxes. Call after a data restore
  /// (e.g. from a Google Drive backup) so the UI reflects the new data.
  void reload() => _load();

  void _load() {
    final box = DBService.box(DBService.meetingsBox);
    _meetings =
        box.values
            .map((e) => Meeting.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    notifyListeners();
  }

  Future<Meeting> addMeeting({
    required String title,
    required String platform,
    required String link,
    String? classId,
    String? sectionId,
    DateTime? scheduledAt,
    String? note,
  }) async {
    final m = Meeting(
      id: _uuid.v4(),
      title: title,
      platform: platform,
      link: link,
      classId: classId,
      sectionId: sectionId,
      scheduledAt: scheduledAt ?? DateTime.now(),
      note: note,
      createdAt: DateTime.now(),
    );
    await DBService.box(DBService.meetingsBox).put(m.id, m.toMap());
    _meetings.insert(0, m);
    _meetings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    notifyListeners();
    return m;
  }

  Future<void> updateMeeting(Meeting m) async {
    await DBService.box(DBService.meetingsBox).put(m.id, m.toMap());
    final idx = _meetings.indexWhere((x) => x.id == m.id);
    if (idx != -1) _meetings[idx] = m;
    _meetings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    notifyListeners();
  }

  Future<void> deleteMeeting(String id) async {
    await DBService.box(DBService.meetingsBox).delete(id);
    _meetings.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
