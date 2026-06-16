import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/manage-login/login_page.dart';
import 'screens/manage-login/dashboards.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Premium modern default
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
        // Handle stream loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          return FutureBuilder<String?>(
            future: authService.getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                );
              }

              if (roleSnapshot.hasError || !roleSnapshot.hasData || roleSnapshot.data == null) {
                // If we fail to get user role, sign out and route to Login
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

              final role = roleSnapshot.data!;
              final email = user.email ?? '';
              final name = user.displayName ?? '';

              // Dynamic dashboard redirection based on roles
              switch (role) {
                case 'student':
                  return StudentDashboard(email: email, name: name);
                case 'lecturer':
                  return LecturerDashboard(email: email, name: name);
                case 'faculty_registrar':
                  return RegistrarDashboard(email: email, name: name);
                default:
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await authService.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid user role: $role. Signing out.')),
                      );
                    }
                  });
                  return const LoginPage();
              }
            },
          );
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}
