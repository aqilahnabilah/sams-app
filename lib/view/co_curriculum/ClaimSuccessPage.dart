import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../main.dart';

import 'AdabClaimListPage.dart';
import 'AddCoCurriculumModulePage.dart';

class ClaimSuccessPage extends StatelessWidget {
  final String message;
  final String staff_id;

  const ClaimSuccessPage({
    super.key,
    required this.message,
    this.staff_id = '',
  });

  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color darkGreen = Color(0xFF22745A);
  static const Color mint = Color(0xFFD8F7E5);
  static const Color red = Color(0xFFC62828);
  static const Color text = Color(0xFF17213A);
  static const Color brown = Color(0xFFA4551D);

  bool get isApproved => message.toLowerCase().contains('approved');
  bool get isRejected => message.toLowerCase().contains('rejected');

  // OOP METHOD: This method returns page title based on claim action.
  String getPageTitle() {
    if (isApproved) return 'Approval Success';
    if (isRejected) return 'Rejection Success';
    return 'Claim Submitted';
  }

  // OOP METHOD: This method returns subtitle based on claim action.
  String getPageSubtitle() {
    if (isApproved) return 'Verified claim outcome';
    if (isRejected) return 'Rejected claim outcome';
    return 'Claim request outcome';
  }

  // OOP METHOD: This method maps user back to previous main screens.
  void mapsToMainMenu(BuildContext context) {
    if (staff_id.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdabClaimListPage(staff_id: staff_id),
        ),
      );
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // OOP METHOD: This method signs out Pusat ADAB staff and returns to login wrapper.
  Future<void> logoutUser(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  // OOP METHOD: This method opens user profile information as a pop-up.
  void displayUserProfileDialog(BuildContext context) {
    final isStaffProfile = staff_id.isNotEmpty;
    final collectionName = isStaffProfile ? 'PusatAdab' : 'Student';
    final documentId = isStaffProfile ? staff_id : '-';
    final title = isStaffProfile ? 'Pusat ADAB Profile' : 'Student Profile';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title, style: const TextStyle(color: text, fontWeight: FontWeight.w900)),
          content: isStaffProfile
              ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection(collectionName)
                      .doc(documentId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: green)));
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
                              child: Text('U', style: TextStyle(color: darkGreen, fontSize: 30, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _profileItem('staff_name', readProfileValue(['staff_name'], staff_id)),
                          _profileItem('staff_email', readProfileValue(['staff_email'], staff_id)),
                          _profileItem('department', readProfileValue(['department'], 'Pusat ADAB')),
                          _profileItem('role', readProfileValue(['role'], 'Pusat ADAB')),
                          _profileItem('status', readProfileValue(['status', 'account_status'], 'Active')),
                        ],
                      ),
                    );
                  },
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: mint,
                        child: Text('U', style: TextStyle(color: darkGreen, fontSize: 30, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _profileItem('Student Profile', 'Open the student record page to view full profile.'),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: green, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  // OOP METHOD: This method shows user actions from the top-right user button.
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
              if (staff_id.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_circle_outline, color: green),
                  title: const Text('Add Module', style: TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCoCurriculumModulePage(staff_id: staff_id)),
                    );
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
    final mainColor = isRejected ? red : darkGreen;

    return Scaffold(
      backgroundColor: bg,
      
      body: Column(
        children: [
          _topHeader(
            title: getPageTitle(),
            subtitle: getPageSubtitle(),
            onBackTap: () => Navigator.maybePop(context),
            onAvatarTap: () => displayProfileMenu(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 18, 30, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isRejected ? const Color(0xFFFFEAEA) : mint,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isRejected ? const Color(0xFFFF9B9B) : const Color(0xFF77E5A6),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('VERIFICATION RESULT'),
                        const SizedBox(height: 16),
                        Text(
                          isApproved
                              ? 'Claim approved successfully'
                              : isRejected
                                  ? 'Claim rejected successfully'
                                  : 'Claim submitted successfully',
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isApproved
                              ? '2 co-curriculum credits have been recorded in the student academic record.'
                              : isRejected
                                  ? 'The rejection status and reason have been saved for the student to view.'
                                  : 'Your claim has been saved with Pending Verification status.',
                          style: const TextStyle(color: text, fontSize: 16, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SYSTEM ACTIONS COMPLETED'),
                        const SizedBox(height: 18),
                        if (isApproved) ...[
                          _actionPill('Status updated to Approved'),
                          _actionPill('2 credits recorded in academic record'),
                          _actionPill('Student notification sent'),
                        ] else if (isRejected) ...[
                          _actionPill('Status updated to Rejected'),
                          _actionPill('Rejection reason stored'),
                          _actionPill('Student notification sent'),
                        ] else ...[
                          _actionPill('Claim stored in database'),
                          _actionPill('Status set to Pending Verification'),
                          _actionPill('Pusat ADAB review required'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => mapsToMainMenu(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
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
      height: 116,
      color: green,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 12, 20, 12),
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
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  child: const Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _profileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: text, fontWeight: FontWeight.w800)),
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
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5)),
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

  Widget _actionPill(String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF77E5A6)),
      ),
      child: Text(label, style: const TextStyle(color: darkGreen, fontSize: 16, height: 1.2)),
    );
  }
}
