import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance.dart';
import '../services/db_service.dart';

class StudentAttendanceStat {
  final int totalDays;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final double percentage;

  StudentAttendanceStat({
    required this.totalDays,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.percentage,
  });
}

class AttendanceProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<AttendanceRecord> _records = [];

  List<AttendanceRecord> get records => List.unmodifiable(_records);

  AttendanceProvider() {
    _load();
  }

  void reload() => _load();

  void _load() {
    final box = DBService.box(DBService.attendanceBox);
    _records =
        box.values
            .map((e) => AttendanceRecord.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<AttendanceRecord> recordsForDate(
    DateTime date, {
    String? classId,
    String? sectionId,
  }) {
    return _records.where((r) {
      final matchesDate = _isSameDay(r.date, date);
      if (!matchesDate) return false;
      if (classId != null && classId.isNotEmpty && r.classId != classId) {
        return false;
      }
      if (sectionId != null && sectionId.isNotEmpty && r.sectionId != sectionId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AttendanceRecord> recordsForStudent(String studentId) {
    return _records.where((r) => r.studentId == studentId).toList();
  }

  AttendanceRecord? recordForStudentOnDate(String studentId, DateTime date) {
    try {
      return _records.firstWhere(
        (r) => r.studentId == studentId && _isSameDay(r.date, date),
      );
    } catch (_) {
      return null;
    }
  }

  /// Bulk save / update attendance for a class/section on a given date.
  /// [studentStatuses] is a map of {studentId: 'Present' | 'Absent' | 'Late' | 'Leave'}.
  Future<void> saveClassAttendance({
    required DateTime date,
    required String classId,
    required String sectionId,
    required Map<String, String> studentStatuses,
    Map<String, String>? studentNotes,
  }) async {
    final box = DBService.box(DBService.attendanceBox);
    final normalizedDate = _normalizeDate(date);

    for (final entry in studentStatuses.entries) {
      final studentId = entry.key;
      final status = entry.value;
      final note = studentNotes?[studentId];

      final existingIndex = _records.indexWhere(
        (r) => r.studentId == studentId && _isSameDay(r.date, normalizedDate),
      );

      if (existingIndex != -1) {
        final existing = _records[existingIndex];
        existing.status = status;
        existing.classId = classId;
        existing.sectionId = sectionId;
        if (note != null) existing.note = note;
        await box.put(existing.id, existing.toMap());
        _records[existingIndex] = existing;
      } else {
        final newRecord = AttendanceRecord(
          id: _uuid.v4(),
          date: normalizedDate,
          studentId: studentId,
          classId: classId,
          sectionId: sectionId,
          status: status,
          note: note,
        );
        await box.put(newRecord.id, newRecord.toMap());
        _records.insert(0, newRecord);
      }
    }

    _records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> saveSingleAttendance(AttendanceRecord record) async {
    final box = DBService.box(DBService.attendanceBox);
    final normalized = AttendanceRecord(
      id: record.id.isEmpty ? _uuid.v4() : record.id,
      date: _normalizeDate(record.date),
      studentId: record.studentId,
      classId: record.classId,
      sectionId: record.sectionId,
      status: record.status,
      note: record.note,
    );

    final idx = _records.indexWhere(
      (r) =>
          r.id == normalized.id ||
          (r.studentId == normalized.studentId &&
              _isSameDay(r.date, normalized.date)),
    );

    if (idx != -1) {
      normalized.id = _records[idx].id;
      _records[idx] = normalized;
    } else {
      _records.insert(0, normalized);
    }

    await box.put(normalized.id, normalized.toMap());
    _records.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteAttendance(String id) async {
    await DBService.box(DBService.attendanceBox).delete(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  StudentAttendanceStat getStudentStats(String studentId) {
    final studentRecords = recordsForStudent(studentId);
    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;

    for (final r in studentRecords) {
      switch (r.status.toLowerCase()) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'leave':
          leave++;
          break;
        default:
          present++;
      }
    }

    final total = studentRecords.length;
    // Late can be counted partially or fully as attendance (here we count present + late)
    final effectivePresent = present + (late * 0.5);
    final percentage = total == 0 ? 100.0 : (effectivePresent / total) * 100.0;

    return StudentAttendanceStat(
      totalDays: total,
      present: present,
      absent: absent,
      late: late,
      leave: leave,
      percentage: percentage,
    );
  }
}
