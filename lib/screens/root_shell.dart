import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'students/students_screen.dart';
import 'classes/classes_screen.dart';
import 'homework/homework_screen.dart';
import 'reports/reports_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    StudentsScreen(),
    ClassesScreen(),
    HomeworkScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.class_rounded),
              label: 'Classes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              label: 'Homework',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
