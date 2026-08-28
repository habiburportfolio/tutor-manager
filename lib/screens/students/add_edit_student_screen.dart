import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/academic_provider.dart';
import '../../models/student.dart';
import '../../models/section.dart';
import '../../utils/formatters.dart';

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
  late final _phoneCtrl = TextEditingController(
    text: widget.existing?.guardianPhone,
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

  @override
  void initState() {
    super.initState();
    _classId = widget.existing?.classId;
    _sectionId = widget.existing?.sectionId;
    _admissionDate = widget.existing?.admissionDate ?? DateTime.now();
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
              decoration: const InputDecoration(labelText: 'Student Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rollCtrl,
              decoration: const InputDecoration(labelText: 'Roll Number *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classId,
              decoration: const InputDecoration(labelText: 'Class *'),
              items: academic.classes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _classId = v;
                _sectionId = null;
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
              decoration: const InputDecoration(labelText: 'Section *'),
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
            TextFormField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Fee *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            // Admission Date field with calendar picker. Defaults to today
            // on creation, but can be corrected/back-dated anytime via edit.
            InkWell(
              onTap: _pickAdmissionDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Admission Date *',
                  suffixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(fmtDate(_admissionDate)),
              ),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _guardianNameCtrl,
              decoration: const InputDecoration(labelText: 'Guardian Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guardian Phone Number *',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
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

    if (widget.existing == null) {
      await provider.addStudent(
        name: _nameCtrl.text.trim(),
        roll: _rollCtrl.text.trim(),
        classId: _classId!,
        sectionId: _sectionId!,
        guardianName: _guardianNameCtrl.text.trim(),
        guardianPhone: _phoneCtrl.text.trim(),
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
      s.guardianPhone = _phoneCtrl.text.trim();
      s.address = _addressCtrl.text.trim();
      s.monthlyFee = double.tryParse(_feeCtrl.text.trim()) ?? 0;
      s.notes = _notesCtrl.text.trim();
      s.admissionDate = _admissionDate;
      await provider.updateStudent(s);
    }

    if (mounted) Navigator.pop(context);
  }
}
