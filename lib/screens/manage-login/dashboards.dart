// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../subjectRegistration/facultyregistrar/main-course.dart';
import '../subjectRegistration/student/list_subject.dart';
import '../subjectRegistration/advisor/subject_approvals.dart';
import '../../main.dart';

import '../../view/co_curriculum/CoCurriculumPage.dart';
import '../../view/co_curriculum/AdabClaimListPage.dart';
import '../../view/co_curriculum/AddCoCurriculumModulePage.dart';

class StudentDashboard extends StatelessWidget {
  final String email;
  final String name;

  const StudentDashboard({
    super.key,
    required this.email,
    required this.name,
  });

  void openCoCurriculumPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoCurriculumPage(
          email: email,
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  title: 'Welcome back,',
                  name: name.isNotEmpty ? name : 'Student',
                  onLogout: () async {
                    await authService.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
                _RoleInfoCard(
                  role: 'STUDENT',
                  email: email,
                  description:
                      'Access your registered subjects, co-curriculum records, student fee and attendance here.',
                  badgeColor: Colors.teal.shade400,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardActionCard(
                        icon: Icons.app_registration,
                        title: 'Register Subjects',
                        color: Colors.teal.shade300,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterSubjectsPage(
                                studentEmail: email,
                                studentName: name,
                              ),
                            ),
                          );
                        },
                      ),
                      DashboardActionCard(
                        icon: Icons.calendar_month,
                        title: 'Co-curriculum',
                        color: Colors.teal.shade300,
                        onTap: () {
                          openCoCurriculumPage(context);
                        },
                      ),
                      DashboardActionCard(
                        icon: Icons.assignment,
                        title: 'Student Fee',
                        color: Colors.teal.shade300,
                      ),
                      DashboardActionCard(
                        icon: Icons.person_outline,
                        title: 'Attendance',
                        color: Colors.teal.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LecturerDashboard extends StatelessWidget {
  final String email;
  final String name;

  const LecturerDashboard({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B192C),
              Color(0xFF1E3E62),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  title: 'Welcome,',
                  name: name.isNotEmpty ? name : 'Lecturer',
                  onLogout: () async {
                    await authService.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
                _RoleInfoCard(
                  role: 'LECTURER',
                  email: email,
                  description:
                      'Manage your student rosters, enter grades, and configure course schedules.',
                  badgeColor: Colors.amber.shade700,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardActionCard(
                        icon: Icons.menu_book,
                        title: 'My Courses',
                        color: Colors.amber.shade400,
                      ),
                      DashboardActionCard(
                        icon: Icons.people,
                        title: 'Student Roster',
                        color: Colors.amber.shade400,
                      ),
                      DashboardActionCard(
                        icon: Icons.fact_check_outlined,
                        title: 'Subject Approvals',
                        color: Colors.amber.shade400,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SubjectApprovalsPage(),
                            ),
                          );
                        },
                      ),
                      DashboardActionCard(
                        icon: Icons.rate_review,
                        title: 'Grading Portal',
                        color: Colors.amber.shade400,
                      ),
                      DashboardActionCard(
                        icon: Icons.announcement,
                        title: 'Announcements',
                        color: Colors.amber.shade400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarDashboard extends StatelessWidget {
  final String email;
  final String name;

  const RegistrarDashboard({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF232526),
              Color(0xFF414345),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  title: 'Administration,',
                  name: name.isNotEmpty ? name : 'Registrar',
                  onLogout: () async {
                    await authService.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
                _RoleInfoCard(
                  role: 'FACULTY REGISTRAR',
                  email: email,
                  description:
                      'Full administrative access to manage faculty registration parameters, courses, lecturers and student lists.',
                  badgeColor: Colors.indigo.shade600,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Administrative Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardActionCard(
                        icon: Icons.add_to_photos,
                        title: 'Manage Courses',
                        color: Colors.indigo.shade300,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ManageCoursesPage(),
                            ),
                          );
                        },
                      ),
                      DashboardActionCard(
                        icon: Icons.supervised_user_circle,
                        title: 'Manage Users',
                        color: Colors.indigo.shade300,
                      ),
                      DashboardActionCard(
                        icon: Icons.settings,
                        title: 'System Settings',
                        color: Colors.indigo.shade300,
                      ),
                      DashboardActionCard(
                        icon: Icons.bar_chart,
                        title: 'Reports & Audits',
                        color: Colors.indigo.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PusatAdabDashboard extends StatelessWidget {
  final String email;
  final String name;

  const PusatAdabDashboard({
    super.key,
    required this.email,
    required this.name,
  });

  void openAdabClaimListPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdabClaimListPage(
          staff_id: email,
        ),
      ),
    );
  }

  void openAddModulePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCoCurriculumModulePage(
          staff_id: email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  title: 'Welcome,',
                  name: name.isNotEmpty ? name : 'Pusat ADAB',
                  onLogout: () async {
                    await authService.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
                _RoleInfoCard(
                  role: 'PUSAT ADAB',
                  email: email,
                  description:
                      'Review student co-curriculum claims, verify completed modules, approve claims, or reject claims with reason.',
                  badgeColor: Colors.teal.shade400,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardActionCard(
                        icon: Icons.verified_user,
                        title: 'Verify Claims',
                        color: Colors.teal.shade300,
                        onTap: () {
                          openAdabClaimListPage(context);
                        },
                      ),
                      DashboardActionCard(
                        icon: Icons.add_circle_outline,
                        title: 'Add Module',
                        color: Colors.teal.shade300,
                        onTap: () {
                          openAddModulePage(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String title;
  final String name;
  final Future<void> Function() onLogout;

  const _DashboardHeader({
    required this.title,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.logout,
            color: Colors.white70,
          ),
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _RoleInfoCard extends StatelessWidget {
  final String role;
  final String email;
  final String description;
  final Color badgeColor;

  const _RoleInfoCard({
    required this.role,
    required this.email,
    required this.description,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}