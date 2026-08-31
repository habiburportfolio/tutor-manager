class Student {
  String id;
  String name;
  String roll;
  String classId;
  String sectionId;
  String guardianName;
  String guardianPhone;
  String? studentPhone; // optional student's personal phone number
  List<String> subjectIds; // optional list of enrolled subjects
  String? address;
  double
  monthlyFee; // fee assigned to this student (can differ from class default)
  DateTime admissionDate;
  bool isActive;
  String? photoPath; // optional local path
  String? notes;

  Student({
    required this.id,
    required this.name,
    required this.roll,
    required this.classId,
    required this.sectionId,
    required this.guardianName,
    required this.guardianPhone,
    this.studentPhone,
    this.subjectIds = const [],
    this.address,
    this.monthlyFee = 0,
    required this.admissionDate,
    this.isActive = true,
    this.photoPath,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'roll': roll,
    'classId': classId,
    'sectionId': sectionId,
    'guardianName': guardianName,
    'guardianPhone': guardianPhone,
    'studentPhone': studentPhone,
    'subjectIds': subjectIds,
    'address': address,
    'monthlyFee': monthlyFee,
    'admissionDate': admissionDate.toIso8601String(),
    'isActive': isActive,
    'photoPath': photoPath,
    'notes': notes,
  };

  factory Student.fromMap(Map map) => Student(
    id: map['id'] as String,
    name: map['name'] as String,
    roll: map['roll']?.toString() ?? '',
    classId: map['classId'] as String,
    sectionId: map['sectionId'] as String,
    guardianName: map['guardianName']?.toString() ?? '',
    guardianPhone: map['guardianPhone']?.toString() ?? '',
    studentPhone: map['studentPhone']?.toString(),
    subjectIds: (map['subjectIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    address: map['address']?.toString(),
    monthlyFee: (map['monthlyFee'] as num?)?.toDouble() ?? 0,
    admissionDate:
        DateTime.tryParse(map['admissionDate']?.toString() ?? '') ??
        DateTime.now(),
    isActive: map['isActive'] as bool? ?? true,
    photoPath: map['photoPath']?.toString(),
    notes: map['notes']?.toString(),
  );
}

