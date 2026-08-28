/// A scheduled/created virtual meeting (Zoom or Google Meet) for a class,
/// section, or the whole coaching center. The app does not integrate with
/// the Zoom/Google Meet APIs directly (that needs a developer/business
/// account); instead it stores the meeting link the admin already created
/// on zoom.us / meet.google.com (or a quick "instant" Google Meet link),
/// and lets them open it and share it with guardians/students via SMS,
/// WhatsApp, or the native share sheet.
class Meeting {
  String id;
  String title;
  String platform; // 'Zoom' or 'Google Meet'
  String link;
  String? classId; // null = all classes
  String? sectionId; // null = all sections of the class
  DateTime scheduledAt;
  String? note;
  DateTime createdAt;

  Meeting({
    required this.id,
    required this.title,
    required this.platform,
    required this.link,
    this.classId,
    this.sectionId,
    required this.scheduledAt,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'platform': platform,
    'link': link,
    'classId': classId,
    'sectionId': sectionId,
    'scheduledAt': scheduledAt.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Meeting.fromMap(Map map) => Meeting(
    id: map['id'] as String,
    title: map['title']?.toString() ?? '',
    platform: map['platform']?.toString() ?? 'Zoom',
    link: map['link']?.toString() ?? '',
    classId: map['classId']?.toString(),
    sectionId: map['sectionId']?.toString(),
    scheduledAt:
        DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
        DateTime.now(),
    note: map['note']?.toString(),
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}
