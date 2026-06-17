// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/Authentication/AuthController.dart';
import '../../provider/StudentFee/PaymentController.dart';
import '../../theme/sams_theme.dart';
import '../subjectRegistration/facultyregistrar/main-course.dart';
import '../subjectRegistration/student/list_subject.dart';
import '../subjectRegistration/advisor/subject_approvals.dart';
import '../../view/StudentFee/StudentFeePage.dart';
import '../../view/StudentFee/PaymentManagement.dart';
import '../../view/co_curriculum/CoCurriculumPage.dart';
import '../../view/co_curriculum/AdabClaimListPage.dart';
<<<<<<< HEAD
import '../../view/co_curriculum/AddCoCurriculumModulePage.dart';
=======
import 'login_page.dart';
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9

/// Common Dashboard Scaffold to maintain the "Dark Gradient" theme (Subject Registration Theme)
class BaseDashboard extends StatelessWidget {
  final String title;
  final String name;
  final String roleLabel;
  final List<Widget> actions;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  const BaseDashboard({
    super.key,
    required this.title,
    required this.name,
    required this.roleLabel,
    required this.children,
    this.actions = const [],
    this.onRefresh,
  });

<<<<<<< HEAD
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

=======
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SamsColors.portalGradient,
          ),
        ),
        child: SafeArea(
<<<<<<< HEAD
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
=======
          child: Column(
            children: [
              // Custom AppBar to fit the gradient background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...actions,
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: () {
                        context.read<AuthController>().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(username: name, roleLabel: roleLabel),
                        const SizedBox(height: 32),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ],
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
=======
}

class _DashboardHeader extends StatelessWidget {
  final String username;
  final String roleLabel;
  const _DashboardHeader({required this.username, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            username.isNotEmpty ? username : 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.tealAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: themeColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
}

class StudentDashboard extends StatelessWidget {
  final String userId;
  final String name;

  const StudentDashboard({super.key, required this.userId, required this.name});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      title: 'Student Dashboard',
      name: name,
      roleLabel: 'Student',
      children: [
        ActionCard(
          title: 'Register Subjects',
          subtitle: 'Enroll in your courses for this semester.',
          icon: Icons.app_registration,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegisterSubjectsPage(studentEmail: userId, studentName: name))),
        ),
<<<<<<< HEAD
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
=======
        ActionCard(
          title: 'Student Fee',
          subtitle: 'View your outstanding balance and history.',
          icon: Icons.receipt_long,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFeePage())),
        ),
        ActionCard(
          title: 'Class Check-In',
          subtitle: 'Submit attendance for your active session.',
          icon: Icons.qr_code_scanner,
          onTap: () => Navigator.pushNamed(context, '/student/check-in'),
        ),
        ActionCard(
          title: 'Attendance History',
          subtitle: 'View your past attendance records.',
          icon: Icons.history,
          onTap: () => Navigator.pushNamed(context, '/student/attendance-history'),
        ),
        ActionCard(
          title: 'Co-curriculum',
          subtitle: 'Manage your activity points and certificates.',
          icon: Icons.calendar_month,
          onTap: () {
             Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CoCurriculumPage(
                  student_id: userId,
                  full_name: name.isNotEmpty ? name : userId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class LecturerDashboard extends StatefulWidget {
  final String userId;
  final String name;

  const LecturerDashboard({super.key, required this.userId, required this.name});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  bool _showAttendance = false;

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      title: 'Lecturer Dashboard',
      name: widget.name,
      roleLabel: 'Lecturer',
      children: [
        ActionCard(
          title: 'Attendance',
          subtitle: 'Manage and generate class codes.',
          icon: Icons.calendar_month,
          onTap: () => setState(() => _showAttendance = !_showAttendance),
        ),
        if (_showAttendance) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12, top: 4),
            child: Text(
              'My Class Sessions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
              ),
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
            ),
          ),
          _sessionCard(context, 'BCS3133', 'Software Engineering Practices', Icons.code),
          _sessionCard(context, 'BCS3143', 'Software Project Management', Icons.assignment),
          _sessionCard(context, 'BCS3233', 'Software Testing', Icons.bug_report),
          const SizedBox(height: 12),
        ],
        ActionCard(
          title: 'Subject Approvals',
          subtitle: 'Review student registration requests.',
          icon: Icons.fact_check_outlined,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubjectApprovalsPage())),
        ),
        ActionCard(
          title: 'My Courses',
          subtitle: 'View your assigned subjects and rosters.',
          icon: Icons.menu_book,
          onTap: () {},
        ),
      ],
    );
  }
<<<<<<< HEAD
=======

  Widget _sessionCard(BuildContext context, String code, String name, IconData icon) {
    return ActionCard(
      title: code,
      subtitle: name,
      icon: icon,
      color: Colors.tealAccent.shade100,
      onTap: () => Navigator.pushNamed(context, '/lecturer/sessions', arguments: {'subjectCode': code, 'subjectName': name}),
    );
  }
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
}

class TreasuryDashboard extends StatelessWidget {
  final String userId;
  final String name;

  const TreasuryDashboard({super.key, required this.userId, required this.name});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      title: 'Treasury Dashboard',
      name: name,
      roleLabel: 'Treasury Officer',
      actions: [
        IconButton(
          icon: const Icon(Icons.cloud_upload, color: Colors.white70),
          tooltip: 'Sync Firestore',
          onPressed: () => _syncData(context),
        ),
      ],
      children: [
        ActionCard(
          title: 'Payment Management',
          subtitle: 'Review and verify student payments.',
          icon: Icons.payments,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentManagement())),
        ),
      ],
    );
  }

  Future<void> _syncData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating Firestore...')));
    final success = await context.read<PaymentController>().uploadDataToFirestore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Sync Successful!' : 'Sync Failed.')));
    }
  }
}

class RegistrarDashboard extends StatelessWidget {
  final String userId;
  final String name;

  const RegistrarDashboard({super.key, required this.userId, required this.name});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      title: 'Registrar Dashboard',
      name: name,
      roleLabel: 'Faculty Registrar',
      children: [
        ActionCard(
          title: 'Manage Courses',
          subtitle: 'Add or modify faculty subject lists.',
          icon: Icons.add_to_photos,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageCoursesPage())),
        ),
<<<<<<< HEAD
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
=======
        ActionCard(
          title: 'User Management',
          subtitle: 'Control student and lecturer access.',
          icon: Icons.supervised_user_circle,
          onTap: () {},
        ),
      ],
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
    );
  }
}

class PusatAdabDashboard extends StatelessWidget {
  final String userId;
  final String name;

  const PusatAdabDashboard({super.key, required this.userId, required this.name});

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
    return BaseDashboard(
      title: 'Pusat Adab',
      name: name,
      roleLabel: 'Adab Officer',
      children: [
        ActionCard(
          title: 'Verify Claims',
          subtitle: 'Review and approve student co-curriculum modules.',
          icon: Icons.verified_user,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AdabClaimListPage(
                  staff_id: userId,
                ),
              ),
            );
          },
        ),
<<<<<<< HEAD
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
=======
        ActionCard(
          title: 'Moral Records',
          subtitle: 'Review student conduct and merit points.',
          icon: Icons.gavel,
          onTap: () {},
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
        ),
        ActionCard(
          title: 'Clearance Status',
          subtitle: 'Verify student behavioral status.',
          icon: Icons.verified_user,
          onTap: () {},
        ),
      ],
    );
  }
}
<<<<<<< HEAD

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
=======
>>>>>>> 559e29bde657f77a589e4a02c7b6beb10f6fc6f9
