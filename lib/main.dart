import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_schedule/screens/login_screen.dart';
import 'package:student_schedule/services/notification_service.dart';
import 'providers/subject_provider.dart';
import 'providers/grade_provider.dart';
import 'providers/event_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => GradeProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()), // Thêm provider mới ở đây
      ],
      child: MaterialApp(
        title: 'Student Schedule',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}