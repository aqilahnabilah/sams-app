import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimConfirmationPage.dart';
import 'ClaimStatusPage.dart';
import 'RegisterModulePage.dart';

class CoCurriculumPage extends StatefulWidget {
  final String email;
  final String name;

  const CoCurriculumPage({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<CoCurriculumPage> createState() => _CoCurriculumPageState();
}

class _CoCurriculumPageState extends State<CoCurriculumPage> {
  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color darkGreen = Color(0xFF22745A);
  static const Color mint = Color(0xFFD8F7E5);
  static const Color text = Color(0xFF17213A);
  static const Color muted = Color(0xFF667085);
  static const Color brown = Color(0xFFA4551D);

  String get studentId => widget.email;
  String get studentName => widget.name.isNotEmpty ? widget.name : widget.email;

  @override
  void initState() {
    super.initState();
    fetchCoCurriculumRecords();
  }

  // OOP METHOD: This method loads student co-curriculum records from controller.
  void fetchCoCurriculumRecords() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(context, listen: false)
          .getStudentRecords(studentId);
    });
  }

  // OOP METHOD: This method maps student to the claim confirmation screen.
  void mapsToClaimConfirmation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimConfirmationPage(
          student_id: studentId,
          full_name: studentName,
        ),
      ),
    ).then((value) => fetchCoCurriculumRecords());
  }

  // OOP METHOD: This method maps student to the claim status screen.
  void mapsToClaimStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimStatusPage(
          student_id: studentId,
          full_name: studentName,
        ),
      ),
    );
  }

  // OOP METHOD: This method maps student to the register module screen.
  void mapsToRegisterModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterModulePage(
          student_id: studentId,
          full_name: studentName,
        ),
      ),
    ).then((value) => fetchCoCurriculumRecords());
  }

  // OOP METHOD: This method signs out the current user and returns to login wrapper.
  Future<void> logoutUser(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  // OOP METHOD: This method opens the student profile pop-up after user selects User Profile.
  void displayUserProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Student Profile',
            style: TextStyle(color: text, fontWeight: FontWeight.w900),
          ),
          content: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('Student')
                .doc(studentId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: green)),
                );
              }

              final data = snapshot.data?.data() ?? {};

              String readProfileValue(List<String> keys, String fallback) {
                for (final key in keys) {
                  final value = data[key];
                  if (value != null && value.toString().trim().isNotEmpty) {
                    return value.toString();
                  }
                }
                return fallback;
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: mint,
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _infoRow('full_name', readProfileValue(['full_name'], studentName)),
                    _infoRow('student_email', readProfileValue(['student_email'], studentId)),
                    _infoRow('program_code', readProfileValue(['program_code'], '-')),
                    _infoRow('program_name', readProfileValue(['program_name'], '-')),
                    _infoRow('faculty', readProfileValue(['faculty', 'Faculty'], '-')),
                    _infoRow('current_sem', readProfileValue(['current_sem'], '-')),
                    _infoRow('co_curriculum_credit', readProfileValue(['co_curriculum_credit'], '0')),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: green, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  // OOP METHOD: This method shows user actions from the top-right user button.
  void displayProfileDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Menu',
                style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: green),
                title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  displayUserProfileDialog(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.app_registration, color: green),
                title: const Text('Register Module', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  mapsToRegisterModule(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await logoutUser(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        final completedCount = controller.getCompletedModuleCount();
        final isEligible = completedCount >= 4;

        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: 'Manage Co-curriculum',
                subtitle: 'Student module overview',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileDialog(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : RefreshIndicator(
                        color: green,
                        onRefresh: () async {
                          await controller.getStudentRecords(studentId);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          child: Column(
                            children: [
                              _progressCard(completedCount, isEligible),
                              const SizedBox(height: 14),
                              _recordCard(controller),
                              const SizedBox(height: 14),
                              _primaryButton(
                                label: 'Submit Claim',
                                onPressed: () => mapsToClaimConfirmation(context),
                              ),
                              const SizedBox(height: 10),
                              _outlineButton(
                                label: 'View Claim Status',
                                onPressed: () => mapsToClaimStatus(context),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topHeader({
    required String title,
    required String subtitle,
    required VoidCallback onBackTap,
    required VoidCallback onAvatarTap,
  }) {
    return Container(
      width: double.infinity,
      height: 104,
      color: green,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 18, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back',
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  child: const Text(
                    'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard(int completedCount, bool isEligible) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MY PROGRESS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statusBox(
                  title: 'Completed Modules',
                  value: '$completedCount / 4',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statusBox(
                  title: 'Eligibility',
                  value: isEligible ? 'Eligible' : 'Not Eligible',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordCard(CoCurriculumController controller) {
    final completedRecords = controller.records
        .where((record) => record.isCompleted())
        .toList();
    final displayRecords = completedRecords.take(3).toList();
    final remaining = completedRecords.length - displayRecords.length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CO-CURRICULUM RECORD'),
          const SizedBox(height: 12),
          if (displayRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _innerDecoration(),
              child: const Text(
                'No completed co-curriculum module yet. Tap the user button to register available modules.',
                style: TextStyle(color: muted, height: 1.35),
              ),
            )
          else
            ...displayRecords.map((record) {
              final module = controller.modules[record.module_id];
              return _moduleTile(
                moduleName: module?.module_name ?? record.module_id,
                category: module?.module_category ?? 'Co-curriculum module',
              );
            }),
          if (remaining > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: mint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF8BE5B5)),
              ),
              child: Text(
                '+$remaining more completed module',
                style: const TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _moduleTile({required String moduleName, required String category}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _innerDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  style: const TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA8EBC5)),
            ),
            child: const Text(
              'Completed',
              style: TextStyle(
                color: darkGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA8EBC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9E5DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  BoxDecoration _innerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6E7EA)),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: brown,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _outlineButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: text,
          side: const BorderSide(color: Color(0xFFE0E2E6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
