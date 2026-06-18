import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimConfirmationPage.dart';
import 'CoCurriculumPage.dart';
import 'RegisterModulePage.dart';

class ClaimStatusPage extends StatefulWidget {
  final String student_id;
  final String full_name;

  const ClaimStatusPage({
    super.key,
    required this.student_id,
    this.full_name = '',
  });

  @override
  State<ClaimStatusPage> createState() => _ClaimStatusPageState();
}

class _ClaimStatusPageState extends State<ClaimStatusPage> {
  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color darkGreen = Color(0xFF22745A);
  static const Color mint = Color(0xFFD8F7E5);
  static const Color yellow = Color(0xFFFFF4C7);
  static const Color text = Color(0xFF17213A);
  static const Color muted = Color(0xFF667085);
  static const Color brown = Color(0xFFA4551D);

  @override
  void initState() {
    super.initState();
    fetchClaimStatus();
  }

  // OOP METHOD: This method retrieves the latest claim status from controller.
  void fetchClaimStatus() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(context, listen: false)
          .getClaimStatus(widget.student_id);
    });
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

  // OOP METHOD: This method maps student to register module screen.
  void mapsToRegisterModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterModulePage(
          student_id: widget.student_id,
          full_name: widget.full_name.isNotEmpty ? widget.full_name : widget.student_id,
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

  // OOP METHOD: This method shows user actions from the top-right avatar.
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
        final claim = controller.claim;

        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: 'Claim Status',
                subtitle: 'Verification progress',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileMenu(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : controller.error_message.isNotEmpty
                        ? _errorBox(controller.error_message)
                        : RefreshIndicator(
                        color: green,
                        onRefresh: () async {
                          await controller.getClaimStatus(widget.student_id);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                          child: claim == null
                              ? _emptyClaim(context)
                              : _statusContent(claim),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
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

  Widget _statusContent(CoCurriculumClaimModel claim) {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('LATEST CLAIM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Co-curriculum Credit Claim',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submitted on ${formatDate(claim.submission_date)}',
                          style: const TextStyle(color: text, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  _statusPill(claim.claim_status),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('CLAIM TIMELINE'),
              const SizedBox(height: 16),
              _timelineBox(
                color: mint,
                border: const Color(0xFF77E5A6),
                title: 'Submitted',
                message: 'Stored in database with ${claim.claim_status.toLowerCase()} status.',
                titleColor: darkGreen,
              ),
              const SizedBox(height: 12),
              _timelineBox(
                color: claim.isApproved() ? mint : yellow,
                border: claim.isApproved() ? const Color(0xFF77E5A6) : const Color(0xFFF2C94C),
                title: claim.isApproved()
                    ? 'Approved'
                    : claim.isRejected()
                        ? 'Rejected'
                        : 'Waiting for review',
                message: claim.isApproved()
                    ? 'Pusat ADAB approved the claim and recorded 2 credits.'
                    : claim.isRejected()
                        ? 'Pusat ADAB rejected the claim. Reason can be viewed in the system.'
                        : 'Pusat ADAB will approve or reject the claim.',
                titleColor: claim.isApproved() ? darkGreen : const Color(0xFFC75E00),
              ),
              const SizedBox(height: 12),
              _timelineBox(
                color: Colors.white,
                border: const Color(0xFFE6E7EA),
                title: 'Notification',
                message: 'Student receives an update after verification.',
                titleColor: text,
              ),
              if (claim.isRejected() &&
                  claim.rejection_reason != null &&
                  claim.rejection_reason!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _timelineBox(
                  color: const Color(0xFFFFEAEA),
                  border: const Color(0xFFFF9B9B),
                  title: 'Rejection reason',
                  message: claim.rejection_reason!,
                  titleColor: const Color(0xFFC62828),
                ),
              ],
            ],
          ),
        ),
      const SizedBox(height: 18),
      _outlineButton(
        label: 'Back to Record',
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

  Widget _errorBox(String message) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('CLAIM STATUS'),
            const SizedBox(height: 14),
            const Text(
              'Cannot load claim status',
              style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: muted, height: 1.35)),
            const SizedBox(height: 16),
            _outlineButton(label: 'Back to Record', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _emptyClaim(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('LATEST CLAIM'),
          const SizedBox(height: 14),
          const Text(
            'No claim submitted yet',
            style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit your co-curriculum credit claim after completing 4 modules.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          _outlineButton(label: 'Back to Record', onPressed: () => Navigator.pop(context)),
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
      constraints: const BoxConstraints(minHeight: 128),
      color: green,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 18, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 42,
                child: IconButton(
                  onPressed: onBackTap,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(width: 4),
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
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.0,
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
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
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
          BoxShadow(color: Colors.black.withOpacity(0.11), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: brown, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2.4),
    );
  }

  Widget _statusPill(String status) {
    final isApproved = status == 'Approved';
    final isRejected = status == 'Rejected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved
            ? mint
            : isRejected
                ? const Color(0xFFFFEAEA)
                : yellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF77E5A6)
              : isRejected
                  ? const Color(0xFFFF9B9B)
                  : const Color(0xFFF2C94C),
        ),
      ),
      child: Text(
        status.replaceAll(' Verification', ''),
        style: TextStyle(
          color: isApproved
              ? darkGreen
              : isRejected
                  ? const Color(0xFFC62828)
                  : const Color(0xFFC75E00),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _timelineBox({
    required Color color,
    required Color border,
    required String title,
    required String message,
    required Color titleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: const TextStyle(color: text, fontSize: 16, height: 1.3)),
        ],
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

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
