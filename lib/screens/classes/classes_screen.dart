import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/school_class.dart';
import '../../providers/academic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import 'class_detail_screen.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context),
        child: const Icon(Icons.add),
      ),
      body: academic.classes.isEmpty
          ? const Center(child: Text('No classes yet. Tap + to add a class.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: academic.classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = academic.classes[i];
                final sectionsCount = academic.sectionsForClass(c.id).length;
                final subjectsCount = academic.subjectsForClass(c.id).length;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimary.withValues(alpha: 0.15),
                      child: const Icon(Icons.class_rounded, color: kPrimary),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$sectionsCount section(s) • $subjectsCount subject(s) • Fee: ${fmtMoney(c.defaultFee)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _showEditClassDialog(context, c);
                        } else if (v == 'delete') {
                          _confirmDelete(context, academic, c.id, c.name);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Class'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Class'),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailScreen(classId: c.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AcademicProvider academic,
    String id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text(
          'This will delete "$name" and all its sections & subjects. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              academic.deleteClass(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: kAccentRed)),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final academic = context.read<AcademicProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Class Name (e.g. Class 5)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Monthly Fee',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              academic.addClass(
                nameCtrl.text.trim(),
                double.tryParse(feeCtrl.text.trim()) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, SchoolClass existingClass) {
    final nameCtrl = TextEditingController(text: existingClass.name);
    final feeCtrl = TextEditingController(
      text: existingClass.defaultFee == 0
          ? ''
          : existingClass.defaultFee.toString(),
    );
    final academic = context.read<AcademicProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Class Name (e.g. Class 5)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Default Monthly Fee',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              existingClass.name = nameCtrl.text.trim();
              existingClass.defaultFee =
                  double.tryParse(feeCtrl.text.trim()) ?? 0;
              academic.updateClass(existingClass);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
