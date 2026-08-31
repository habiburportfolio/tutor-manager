import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../models/student.dart';
import '../../models/section.dart';
import '../../models/subject.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? existing;
  const AddEditStudentScreen({super.key, this.existing});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _rollCtrl = TextEditingController(text: widget.existing?.roll);
  late final _guardianNameCtrl = TextEditingController(
    text: widget.existing?.guardianName,
  );
  late final _guardianPhoneCtrl = TextEditingController(
    text: widget.existing?.guardianPhone,
  );
  late final _studentPhoneCtrl = TextEditingController(
    text: widget.existing?.studentPhone,
  );
  late final _addressCtrl = TextEditingController(
    text: widget.existing?.address,
  );
  late final _feeCtrl = TextEditingController(
    text: widget.existing != null ? widget.existing!.monthlyFee.toString() : '',
  );
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes);

  String? _classId;
  String? _sectionId;
  late DateTime _admissionDate;
  final Set<String> _selectedSubjectIds = {};

  @override
  void initState() {
    super.initState();
    _classId = widget.existing?.classId;
    _sectionId = widget.existing?.sectionId;
    _admissionDate = widget.existing?.admissionDate ?? DateTime.now();
    if (widget.existing != null) {
      _selectedSubjectIds.addAll(widget.existing!.subjectIds);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _studentPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAdmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _admissionDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final sections = _classId != null
        ? academic.sectionsForClass(_classId!)
        : <Section>[];
    final classSubjects = _classId != null
        ? academic.subjectsForClass(_classId!)
        : <Subject>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Student' : 'Edit Student'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Student Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rollCtrl,
              decoration: const InputDecoration(
                labelText: 'Roll Number *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classId,
              decoration: const InputDecoration(
                labelText: 'Class *',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: academic.classes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _classId = v;
                _sectionId = null;
                _selectedSubjectIds.clear();
                final cls = academic.classById(v ?? '');
                if (cls != null && _feeCtrl.text.isEmpty) {
                  _feeCtrl.text = cls.defaultFee.toString();
                }
              }),
              validator: (v) => v == null ? 'Select a class' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sectionId,
              decoration: const InputDecoration(
                labelText: 'Section *',
                prefixIcon: Icon(Icons.grid_view_rounded),
              ),
              items: sections
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('Section ${s.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _sectionId = v),
              validator: (v) => v == null ? 'Select a section' : null,
            ),
            const SizedBox(height: 12),

            // Optional Subject Selection during Admission
            if (_classId != null && classSubjects.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.book_outlined, size: 18, color: kPrimary),
                              const SizedBox(width: 6),
                              const Text(
                                'Enrolled Subjects (Optional)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedSubjectIds.length == classSubjects.length) {
                                      _selectedSubjectIds.clear();
                                    } else {
                                      _selectedSubjectIds.addAll(classSubjects.map((s) => s.id));
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedSubjectIds.length == classSubjects.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: classSubjects.map((sub) {
                          final selected = _selectedSubjectIds.contains(sub.id);
                          return FilterChip(
                            label: Text(sub.name),
                            selected: selected,
                            selectedColor: kPrimary.withValues(alpha: 0.2),
                            checkmarkColor: kPrimary,
                            labelStyle: TextStyle(
                              color: selected ? kPrimary : null,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedSubjectIds.add(sub.id);
                                } else {
                                  _selectedSubjectIds.remove(sub.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Fee *',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickAdmissionDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Admission Date *',
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(fmtDate(_admissionDate)),
              ),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _guardianNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Guardian Name',
                prefixIcon: Icon(Icons.supervisor_account_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guardianPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guardian Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'e.g. 017XXXXXXXX',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _studentPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Student's Own Phone Number (Optional)",
                prefixIcon: Icon(Icons.phone_android_rounded),
                hintText: 'e.g. 018XXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  widget.existing == null ? 'Add Student' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<StudentProvider>();
    final sPhone = _studentPhoneCtrl.text.trim().isEmpty
        ? null
        : _studentPhoneCtrl.text.trim();

    if (widget.existing == null) {
      await provider.addStudent(
        name: _nameCtrl.text.trim(),
        roll: _rollCtrl.text.trim(),
        classId: _classId!,
        sectionId: _sectionId!,
        guardianName: _guardianNameCtrl.text.trim(),
        guardianPhone: _guardianPhoneCtrl.text.trim(),
        studentPhone: sPhone,
        subjectIds: _selectedSubjectIds.toList(),
        address: _addressCtrl.text.trim(),
        monthlyFee: double.tryParse(_feeCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim(),
        admissionDate: _admissionDate,
      );
    } else {
      final s = widget.existing!;
      s.name = _nameCtrl.text.trim();
      s.roll = _rollCtrl.text.trim();
      s.classId = _classId!;
      s.sectionId = _sectionId!;
      s.guardianName = _guardianNameCtrl.text.trim();
      s.guardianPhone = _guardianPhoneCtrl.text.trim();
      s.studentPhone = sPhone;
      s.subjectIds = _selectedSubjectIds.toList();
      s.address = _addressCtrl.text.trim();
      s.monthlyFee = double.tryParse(_feeCtrl.text.trim()) ?? 0;
      s.notes = _notesCtrl.text.trim();
      s.admissionDate = _admissionDate;
      await provider.updateStudent(s);
    }

    if (mounted) Navigator.pop(context);
  }
}

