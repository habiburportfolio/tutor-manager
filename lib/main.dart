import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart';
import 'providers/academic_provider.dart';
import 'providers/student_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/homework_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/language_provider.dart';
import 'utils/theme.dart';
import 'screens/root_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  runApp(const TutorManagerApp());
}

class TutorManagerApp extends StatelessWidget {
  const TutorManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => HomeworkProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Tutor Manager',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const RootShell(),
      ),
    );
  }
}
