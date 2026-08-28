import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/theme.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // NOTE: We manage our own TabController (instead of relying on
    // DefaultTabController.of(context)) because the FAB below lives in the
    // same build() as the tab bar itself. DefaultTabController.of(context)
    // requires `context` to be a DESCENDANT of DefaultTabController, but the
    // context available to the FAB's onPressed here is this widget's own
    // build context (an ANCESTOR of DefaultTabController, since it creates
    // it). That mismatch caused `DefaultTabController.of(context)` to throw
    // at runtime and silently swallow the "Add" tap - this is the root cause
    // of the "can't add section/subject" bug. Using an explicit
    // TabController avoids this pitfall entirely.
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final students = context.watch<StudentProvider>();
    final cls = academic.classById(widget.classId);
    if (cls == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Class')),
        body: const Center(child: Text('Class not found')),
      );
    }

    final sections = academic.sectionsForClass(widget.classId);
    final subjects = academic.subjectsForClass(widget.classId);

    return Scaffold(
      appBar: AppBar(
        title: Text(cls.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sections'),
            Tab(text: 'Subjects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _sectionsTab(context, academic, students, sections),
          _subjectsTab(context, academic, subjects),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, academic),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sectionsTab(
    BuildContext context,
    AcademicProvider academic,
    StudentProvider students,
    List sections,
  ) {
    if (sections.isEmpty) {
      return const Center(child: Text('No sections yet. Tap + to add.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final sec = sections[i];
        final count = students.byClassSection(widget.classId, sec.id).length;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.groups_rounded, color: kPrimary),
            title: Text('Section ${sec.name}'),
            subtitle: Text('$count student(s)'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: kAccentRed),
              onPressed: () => academic.deleteSection(sec.id),
            ),
          ),
        );
      },
    );
  }

  Widget _subjectsTab(
    BuildContext context,
    AcademicProvider academic,
    List subjects,
  ) {
    if (subjects.isEmpty) {
      return const Center(child: Text('No subjects yet. Tap + to add.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final sub = subjects[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: kPrimary),
            title: Text(sub.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: kAccentRed),
              onPressed: () => academic.deleteSubject(sub.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, AcademicProvider academic) {
    final tabIndex = _tabController.index;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tabIndex == 0 ? 'Add Section' : 'Add Subject'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tabIndex == 0
                ? 'Section Name (e.g. A)'
                : 'Subject Name (e.g. Mathematics)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              if (tabIndex == 0) {
                academic.addSection(widget.classId, ctrl.text.trim());
              } else {
                academic.addSubject(widget.classId, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
