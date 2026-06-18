import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimStatusPage.dart';
import 'CoCurriculumPage.dart';
import 'RegisterModulePage.dart';

class ClaimConfirmationPage extends StatefulWidget {
  final String student_id;
  final String full_name;

  const ClaimConfirmationPage({
    super.key,
    required this.student_id,
    required this.full_name,
  });

  @override
  State<ClaimConfirmationPage> createState() => _ClaimConfirmationPageState();
}

class _ClaimConfirmationPageState extends State<ClaimConfirmationPage> {
  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color darkGreen = Color(0xFF22745A);
  static const Color mint = Color(0xFFD8F7E5);
  static const Color yellow = Color(0xFFFFF4C7);
  static const Color redBg = Color(0xFFFFEAEA);
  static const Color red = Color(0xFFB42318);
  static const Color text = Color(0xFF17213A);
  static const Color muted = Color(0xFF667085);
  static const Color brown = Color(0xFFA4551D);

  bool isChecking = true;
  bool isEligible = false;
  bool hasDuplicateClaim = false;
  String? notice;

  @override
  void initState() {
    super.initState();
    checkClaimRequirement();
  }

  // OOP METHOD: This method checks eligibility and duplicate claim before submission.
  Future<void> checkClaimRequirement() async {
    final controller = Provider.of<CoCurriculumController>(context, listen: false);

    final eligible = await controller.checkEligibility(widget.student_id);
    final duplicate = await controller.checkDuplicateClaim(widget.student_id);

    if (mounted) {
      setState(() {
        isEligible = eligible;
        hasDuplicateClaim = duplicate;
        isChecking = false;
      });
    }
  }

  // OOP METHOD: This method submits a co-curriculum claim and opens claim status page.
  Future<void> submitClaimRequest(BuildContext context) async {
    final controller = Provider.of<CoCurriculumController>(context, listen: false);
    final result = await controller.submitClaim(widget.student_id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
    );

    if (result == 'Claim submitted successfully.' ||
        result == 'Co-curriculum credit has already been claimed.') {
      await controller.getClaimStatus(widget.student_id);

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClaimStatusPage(
            student_id: widget.student_id,
            full_name: widget.full_name,
          ),
        ),
      );
    } else {
      setState(() => notice = result);
    }
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

  // OOP METHOD: This method maps student to the register module screen.
  void mapsToRegisterModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterModulePage(
          student_id: widget.student_id,
          full_name: widget.full_name,
        ),
      ),
    );
  }

  // OOP METHOD: This method opens student profile information as a pop-up.
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
                .doc(widget.student_id)
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
                    _profileItem('full_name', readProfileValue(['full_name'], widget.full_name.isNotEmpty ? widget.full_name : widget.student_id)),
                    _profileItem('student_email', readProfileValue(['student_email'], widget.student_id)),
                    _profileItem('program_code', readProfileValue(['program_code'], '-')),
                    _profileItem('program_name', readProfileValue(['program_name'], '-')),
                    _profileItem('faculty', readProfileValue(['faculty', 'Faculty'], '-')),
                    _profileItem('current_sem', readProfileValue(['current_sem'], '-')),
                    _profileItem('co_curriculum_credit', readProfileValue(['co_curriculum_credit'], '0')),
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

  // OOP METHOD: This method shows the user menu from the top-right avatar.
  void displayProfileMenu(BuildContext context) {
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
              const Text('User Menu', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900)),
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
        final remaining = (4 - completedCount).clamp(0, 4).toInt();

        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: isEligible && !hasDuplicateClaim
                    ? 'Claim Confirmation'
                    : 'Claim Blocked',
                subtitle: isEligible && !hasDuplicateClaim
                    ? 'Submit co-curriculum claim'
                    : 'Exception flow message',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileMenu(context),
              ),
              Expanded(
                child: isChecking || controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: isEligible && !hasDuplicateClaim
                            ? _confirmationContent(context, completedCount)
                            : _blockedContent(context, completedCount, remaining),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _confirmationContent(BuildContext context, int completedCount) {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('ELIGIBILITY CHECK'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have completed $completedCount modules',
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are eligible to submit a co-curriculum credit claim.',
                      style: TextStyle(color: muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('CLAIM SUMMARY'),
              const SizedBox(height: 16),
              _summaryRow('Claim Type', 'Co-curriculum Credit'),
              _summaryRow('Credits', '2 Credits'),
              _summaryRow('Status', 'Pending Verification'),
            ],
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 14),
          _noticeBox(notice!, success: notice == 'Claim submitted successfully.'),
        ],
        const SizedBox(height: 16),
        _primaryButton(
          label: 'Confirm',
          onPressed: () => submitClaimRequest(context),
        ),
        const SizedBox(height: 10),
        _outlineButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _blockedContent(BuildContext context, int completedCount, int remaining) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF4D4D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('REQUIREMENT NOT MET'),
              const SizedBox(height: 14),
              Text(
                hasDuplicateClaim
                    ? 'Claim cannot be submitted'
                    : 'Claim cannot be submitted',
                style: const TextStyle(
                  color: red,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hasDuplicateClaim
                    ? 'Co-curriculum credit has already been claimed.'
                    : 'You must complete at least 4 co-curriculum modules before submitting a claim.',
                style: const TextStyle(color: text, fontSize: 16, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('PROGRESS STATUS'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _yellowStatus('Completed', '$completedCount / 4'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _yellowStatus(
                      'Remaining',
                      remaining == 1 ? '1 module' : '$remaining modules',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: redBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF9B9B)),
          ),
          child: const Text(
            'Duplicate claim: Co-curriculum credit has already been claimed.',
            style: TextStyle(color: Color(0xFFC62828), fontSize: 16, height: 1.35),
          ),
        ),
        const SizedBox(height: 18),
        _outlineButton(label: 'Back to Record', onPressed: () => Navigator.pop(context)),
      ],
    );
  }


  Widget _profileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
        ],
      ),
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
    color: green,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 22,
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
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: brown,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 14))),
          Text(
            value,
            style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _yellowStatus(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2C94C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: text, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC75E00),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBox(String message, {required bool success}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success ? yellow : redBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: success ? const Color(0xFFF2C94C) : const Color(0xFFFF9B9B)),
      ),
      child: Text(
        message,
        style: TextStyle(color: success ? const Color(0xFF8A5B00) : const Color(0xFFC62828)),
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
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
