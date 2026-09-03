import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'db_service.dart';

/// Exports/imports ALL app data (students, classes, sections, subjects,
/// payments, expenses, homework, settings) as a single JSON backup file.
///
/// Upload to Google Drive is done via the native Android/iOS share sheet
/// (using [Share.shareXFiles]), which already lists "Save to Drive" /
/// "Google Drive" as one of the destinations on any device that has the
/// Drive app installed - this avoids needing a Google Sign-In + Drive API
/// OAuth integration just to move a file into the user's own Drive.
///
/// IMPORTANT: This implementation works purely in-memory (bytes) instead
/// of writing to a temp directory via `path_provider` / `dart:io File`.
/// `path_provider` has NO Web implementation, which was causing a
/// `MissingPluginException` when the backup button was tapped while
/// running the Flutter Web preview. Using `XFile.fromData(...)` for
/// sharing and `withData: true` for picking works uniformly on Web,
/// Android and iOS without touching the filesystem directly.
///
/// Restoring a backup is purely additive: every record is written back
/// into its original Hive box using the same `id` key it was exported
/// with, so restoring does not clash with / wipe unrelated existing data
/// unless the same id already exists (in which case it is safely
/// overwritten with the backed-up version, exactly like `put()` upserts
/// already work everywhere else in this codebase).
class BackupService {
  static const String _formatVersion = '1';

  /// Reads every Hive box declared in [DBService.allBoxNames] into a single
  /// JSON-serializable map.
  static Map<String, dynamic> exportAllData() {
    final Map<String, dynamic> data = {};
    for (final boxName in DBService.allBoxNames) {
      final box = DBService.box(boxName);
      final Map<String, dynamic> entries = {};
      for (final key in box.keys) {
        final value = box.get(key);
        entries[key.toString()] = _sanitize(value);
      }
      data[boxName] = entries;
    }
    return {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Tutor Manager',
      'data': data,
    };
  }

  /// Recursively converts Hive-stored values (which may be
  /// LinkedHashMap/LinkedHashList under the hood) into plain
  /// Map/List/primitive types that `jsonEncode` can handle directly.
  static dynamic _sanitize(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value; // String, num, bool, null already JSON-safe
  }

  static String _backupFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'tutor_manager_backup_$timestamp.json';
  }

  /// Builds the backup JSON bytes entirely in memory (no filesystem access -
  /// safe on Web, Android and iOS alike).
  static Uint8List _buildBackupBytes() {
    final data = exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  /// Creates the backup in memory and opens the native share sheet so the
  /// user can send it to Google Drive (or any other app: WhatsApp, Email,
  /// Bluetooth, etc). Returns the file name that was shared (useful for
  /// showing a success message).
  static Future<String> backupToGoogleDrive() async {
    final bytes = _buildBackupBytes();
    final fileName = _backupFileName();
    final xFile = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'application/json',
    );
    await Share.shareXFiles(
      [xFile],
      text:
          'Tutor Manager data backup. Choose "Google Drive" / "Save to Drive" '
          'from the list to upload it to your Google Drive.',
      subject:
          'Tutor Manager Backup - ${DateTime.now().toIso8601String().split('T').first}',
    );
    return fileName;
  }

  /// Lets the user pick a previously exported `.json` backup file (this
  /// works for a file picked from Google Drive too, since the Android file
  /// picker / "Files" app can browse Drive-synced files) and restores all
  /// its data back into the local Hive boxes.
  ///
  /// Uses `withData: true` so the file bytes are read directly by the
  /// picker itself (works on Web where there is no accessible file path).
  ///
  /// Returns a summary map of how many records were restored per box, or
  /// null if the user cancelled the file picker.
  static Future<Map<String, int>?> pickAndRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null) return null;

    final content = utf8.decode(bytes);
    return restoreFromJson(content);
  }

  /// Parses a backup JSON string and writes every record back into its
  /// Hive box (upsert by id - additive, non-destructive to unrelated data).
  static Future<Map<String, int>> restoreFromJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = (decoded['data'] as Map?) ?? {};

    final Map<String, int> summary = {};
    for (final boxName in DBService.allBoxNames) {
      final boxData = data[boxName];
      if (boxData is! Map) continue;
      final box = DBService.box(boxName);
      int count = 0;
      for (final entry in boxData.entries) {
        await box.put(entry.key, entry.value);
        count++;
      }
      summary[boxName] = count;
    }
    return summary;
  }

  /// Human-readable label for a box name, used in restore-summary UI.
  static String boxLabel(String boxName) {
    switch (boxName) {
      case DBService.studentsBox:
        return 'Students';
      case DBService.classesBox:
        return 'Classes';
      case DBService.sectionsBox:
        return 'Sections';
      case DBService.subjectsBox:
        return 'Subjects';
      case DBService.paymentsBox:
        return 'Payments';
      case DBService.expensesBox:
        return 'Expenses';
      case DBService.homeworkBox:
        return 'Homework';
      case DBService.settingsBox:
        return 'Settings';
      case DBService.meetingsBox:
        return 'Meetings';
      case DBService.attendanceBox:
        return 'Attendance';
      case DBService.otherIncomeBox:
        return 'Other Income';
      default:
        return boxName;
    }
  }
}
