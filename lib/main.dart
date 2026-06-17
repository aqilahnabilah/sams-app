import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/manage-login/login_page.dart';
import 'screens/manage-login/dashboards.dart';
import 'provider/co_curriculum/CoCurriculumController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => CoCurriculumController(),
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
        }

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
          );
        }

        return const LoginPage();
      },
    );
  }
}
