import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/Authentication/UserModel.dart';
import '../../provider/Authentication/AuthController.dart';
import 'login_page.dart';

class AuthRouteGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;

  const AuthRouteGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginPage();
    }

    final userRole = UserModel.normalizeRole(auth.currentUser?.role);
    final normalizedAllowedRoles = allowedRoles.map(UserModel.normalizeRole).toList();

    if (normalizedAllowedRoles.contains(userRole)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: const Color(0xFF0C855E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to access this page. Required roles: ${allowedRoles.join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C855E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
