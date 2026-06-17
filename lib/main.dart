import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/manage-login/login_page.dart';
import 'screens/manage-login/dashboards.dart';
<<<<<<< HEAD
=======

import 'provider/Authentication/AuthController.dart';
import 'provider/Authentication/LoginController.dart';
import 'provider/Authentication/RegisterController.dart';
import 'provider/StudentFee/PaymentController.dart';
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
import 'provider/co_curriculum/CoCurriculumController.dart';
import 'provider/Attendance/AttendanceController.dart';
import 'provider/Attendance/ClassCodeController.dart';
import 'provider/Attendance/LocationVerificationController.dart';
import 'domain/Authentication/UserModel.dart';

import 'view/Attendance/StudentCheckInPage.dart';
import 'view/Attendance/AttendanceHistoryPage.dart';
import 'view/Attendance/AttendanceStatusPage.dart';
import 'view/Attendance/AttendanceRecordPage.dart';
import 'view/Attendance/LectureAttendancePage.dart';
import 'view/Attendance/GenerateClassCodePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (context) => LoginController(context.read<AuthController>())),
        ChangeNotifierProvider(create: (context) => RegisterController(context.read<AuthController>())),
        ChangeNotifierProvider(create: (_) => PaymentController()),
        ChangeNotifierProvider(create: (_) => CoCurriculumController()),
        ChangeNotifierProvider(create: (_) => LocationVerification()),
        ChangeNotifierProvider(create: (_) => ClassCodeController()),
        ChangeNotifierProxyProvider2<LocationVerification, ClassCodeController, AttendanceController>(
          create: (context) => AttendanceController(
            locationVerification: context.read<LocationVerification>(),
            classCodeController: context.read<ClassCodeController>(),
          ),
          update: (context, location, code, previous) => AttendanceController(
            locationVerification: location,
            classCodeController: code,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMS Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/student/check-in': (context) => const AuthWrapper(target: 'check-in'),
        '/student/attendance-history': (context) => const AuthWrapper(target: 'attendance-history'),
        '/student/attendance-status': (context) => const AuthWrapper(target: 'attendance-status'),
        '/lecturer/sessions': (context) => const AuthWrapper(target: 'lecturer-sessions'),
        '/lecturer/attendance-records': (context) => const AuthWrapper(target: 'attendance-records'),
        '/lecturer/generate-code': (context) => const AuthWrapper(target: 'generate-code'),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final String? target;
  const AuthWrapper({super.key, this.target});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (auth.isLoggedIn) {
      final user = auth.currentUser!;
      
      if (target != null) {
        switch (target) {
          case 'check-in':
            return const StudentCheckInPage();
          case 'attendance-history':
            return const AttendanceHistoryPage();
          case 'attendance-status':
            return const AttendanceStatusPage();
          case 'lecturer-sessions':
            return const LectureAttendancePage();
          case 'attendance-records':
            return const AttendanceRecordPage();
          case 'generate-code':
            return const GenerateClassCodePage();
        }
      }

<<<<<<< HEAD
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          return FutureBuilder<List<String?>>(
            future: Future.wait([
              authService.getUserRole(user.uid),
              authService.getUserName(user.uid),
            ]),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                );
              }

              if (roleSnapshot.hasError ||
                  !roleSnapshot.hasData ||
                  roleSnapshot.data == null ||
                  roleSnapshot.data!.isEmpty ||
                  roleSnapshot.data!.first == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await authService.signOut();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to load user role. Signing out.'),
                      ),
                    );
                  }
                });

                return const LoginPage();
              }

              final role = roleSnapshot.data![0] ?? '';
              final email = user.email ?? '';
              final storedName = roleSnapshot.data![1] ?? '';
              final name = storedName.isNotEmpty ? storedName : (user.displayName ?? '');

              switch (role) {
                case 'student':
                  return StudentDashboard(email: email, name: name);

                case 'lecturer':
                  return LecturerDashboard(email: email, name: name);

                case 'faculty_registrar':
                  return RegistrarDashboard(email: email, name: name);

                case 'pusat_adab':
                  return PusatAdabDashboard(email: email, name: name);

                default:
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await authService.signOut();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid user role: $role. Signing out.'),
                        ),
                      );
                    }
                  });

                  return const LoginPage();
              }
            },
=======
      switch (user.role) {
        case UserModel.roleStudent:
          return StudentDashboard(
            userId: user.userId,
            name: user.username,
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
          );

        case UserModel.roleLecturer:
          return LecturerDashboard(
            userId: user.userId,
            name: user.username,
          );

        case UserModel.roleFacultyRegistrar:
          return RegistrarDashboard(
            userId: user.userId,
            name: user.username,
          );
          
        case UserModel.roleTreasury:
          return TreasuryDashboard(
            userId: user.userId,
            name: user.username,
          );
          
        case UserModel.rolePusatAdab:
          return PusatAdabDashboard(
            userId: user.userId,
            name: user.username,
          );

        default:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            auth.logout();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid user role: ${user.role}. Signing out.',
                ),
              ),
            );
          });

          return const LoginPage();
      }
    }

    return const LoginPage();
  }
}
