import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_logo.dart';

class AttendanceScreen extends StatefulWidget {
  final String? initialClassId;
  final String? initialSectionId;

  const AttendanceScreen({
    super.key,
    this.initialClassId,
    this.initialSectionId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  String? _selectedSectionId;
  final Map<String, String> _statuses = {};
  final Map<String, String> _notes = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _selectedSectionId = widget.initialSectionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAttendanceData();
    });
  }

  void _initAttendanceData() {
    final academic = context.read<AcademicProvider>();
    final attendance = context.read<AttendanceProvider>();

    if (_selectedClassId == null && academic.classes.isNotEmpty) {
      _selectedClassId = academic.classes.first.id;
    }

    if (_selectedClassId != null) {
      final availableSections = academic.sectionsForClass(_selectedClassId!);
      if (_selectedSectionId == null ||
          !availableSections.any((s) => s.id == _selectedSectionId)) {
        _selectedSectionId = availableSections.isNotEmpty ? availableSections.first.id : null;
      }
    }

    _loadExistingStatuses(attendance);
  }

  void _loadExistingStatuses(AttendanceProvider attendance) {
    _statuses.clear();
    _notes.clear();

    final students = context.read<StudentProvider>().students;
    final relevantStudents = students.where((s) {
      if (!s.isActive) return false;
      if (_selectedClassId != null && s.classId != _selectedClassId) return false;
      if (_selectedSectionId != null && s.sectionId != _selectedSectionId) return false;
      return true;
    }).toList();

    for (final s in relevantStudents) {
      final existing = attendance.recordForStudentOnDate(s.id, _selectedDate);
      if (existing != null) {
        _statuses[s.id] = existing.status;
        if (existing.note != null) _notes[s.id] = existing.note!;
      } else {
        // Default to Present if not marked yet
        _statuses[s.id] = 'Present';
      }
    }

    setState(() {
      _isDirty = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      if (mounted) {
        _loadExistingStatuses(context.read<AttendanceProvider>());
      }
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final key in _statuses.keys) {
        _statuses[key] = status;
      }
      _isDirty = true;
    });
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Class and Section')),
      );
      return;
    }

    final attendance = context.read<AttendanceProvider>();
    await attendance.saveClassAttendance(
      date: _selectedDate,
      classId: _selectedClassId!,
      sectionId: _selectedSectionId!,
      studentStatuses: _statuses,
      studentNotes: _notes,
    );

    if (!mounted) return;
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance saved for ${fmtDate(_selectedDate)} (${_statuses.length} students)',
        ),
        backgroundColor: kAccentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final studentProv = context.watch<StudentProvider>();
    final attendance = context.watch<AttendanceProvider>();

    // Auto-select class & section if needed
    if (_selectedClassId == null && academic.classes.isNotEmpty) {
      _selectedClassId = academic.classes.first.id;
      final sections = academic.sectionsForClass(_selectedClassId!);
      _selectedSectionId = sections.isNotEmpty ? sections.first.id : null;
    }

    final sections = _selectedClassId != null
        ? academic.sectionsForClass(_selectedClassId!)
        : [];

    final activeStudents = studentProv.students.where((s) {
      if (!s.isActive) return false;
      if (_selectedClassId != null && s.classId != _selectedClassId) return false;
      if (_selectedSectionId != null && s.sectionId != _selectedSectionId) return false;
      return true;
    }).toList()
      ..sort((a, b) => int.tryParse(a.roll)?.compareTo(int.tryParse(b.roll) ?? 0) ?? a.roll.compareTo(b.roll));

    // Ensure all active students have a default status in map
    for (final s in activeStudents) {
      if (!_statuses.containsKey(s.id)) {
        final existing = attendance.recordForStudentOnDate(s.id, _selectedDate);
        _statuses[s.id] = existing?.status ?? 'Present';
        if (existing?.note != null) _notes[s.id] = existing!.note!;
      }
    }

    // Counters
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    int leaveCount = 0;

    for (final s in activeStudents) {
      final st = _statuses[s.id] ?? 'Present';
      if (st == 'Present') presentCount++;
      else if (st == 'Absent') absentCount++;
      else if (st == 'Late') lateCount++;
      else if (st == 'Leave') leaveCount++;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 10),
            const Text('Student Hajira (হাজিরা)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Change Date',
            onPressed: _pickDate,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activeStudents.length} Students Total',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Present: $presentCount | Absent: $absentCount | Late: $lateCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDirty ? kAccentOrange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: activeStudents.isEmpty ? null : _saveAttendance,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isDirty ? 'Save Attendance *' : 'Saved (Save Again)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter & Date Header
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Date Bar
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.today_rounded, color: kPrimary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              fmtDate(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Tap to change date',
                          style: TextStyle(fontSize: 11, color: kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Class & Section Pickers
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        items: academic.classes
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedClassId = v;
                            final newSecs = academic.sectionsForClass(v ?? '');
                            _selectedSectionId = newSecs.isNotEmpty ? newSecs.first.id : null;
                          });
                          _loadExistingStatuses(context.read<AttendanceProvider>());
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSectionId,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        items: sections
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedSectionId = v);
                          _loadExistingStatuses(context.read<AttendanceProvider>());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Batch Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kAccentGreen,
                          side: const BorderSide(color: kAccentGreen),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _markAll('Present'),
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Mark All Present', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kAccentRed,
                          side: const BorderSide(color: kAccentRed),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _markAll('Absent'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Mark All Absent', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance Summary Counters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _counterBadge('Present', presentCount, kAccentGreen),
                _counterBadge('Absent', absentCount, kAccentRed),
                _counterBadge('Late', lateCount, kAccentOrange),
                _counterBadge('Leave', leaveCount, Colors.blue),
              ],
            ),
          ),

          // Students Attendance List
          Expanded(
            child: activeStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_off_rounded, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'No active students in selected Class / Section.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: activeStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = activeStudents[i];
                      final currentStatus = _statuses[s.id] ?? 'Present';

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getStatusColor(currentStatus).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: kPrimary.withValues(alpha: 0.15),
                                    child: Text(
                                      s.roll.isNotEmpty ? s.roll : '${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Roll: ${s.roll} • ${s.guardianPhone}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentStatus,
                                      style: TextStyle(
                                        color: _getStatusColor(currentStatus),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 4-way Status Selector Segment
                              Row(
                                children: [
                                  _statusButton(s.id, 'Present', 'P', kAccentGreen, currentStatus),
                                  const SizedBox(width: 6),
                                  _statusButton(s.id, 'Absent', 'A', kAccentRed, currentStatus),
                                  const SizedBox(width: 6),
                                  _statusButton(s.id, 'Late', 'L', kAccentOrange, currentStatus),
                                  const SizedBox(width: 6),
                                  _statusButton(s.id, 'Leave', 'LV', Colors.blue, currentStatus),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    String studentId,
    String status,
    String shortLabel,
    Color color,
    String currentStatus,
  ) {
    final isSelected = currentStatus.toLowerCase() == status.toLowerCase();

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _statuses[studentId] = status;
            _isDirty = true;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$shortLabel ($status)',
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _counterBadge(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return kAccentGreen;
      case 'absent':
        return kAccentRed;
      case 'late':
        return kAccentOrange;
      case 'leave':
        return Colors.blue;
      default:
        return kAccentGreen;
    }
  }
}
