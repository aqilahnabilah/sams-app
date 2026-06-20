import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimSuccessPage.dart';
import 'AdabClaimListPage.dart';
import 'AddCoCurriculumModulePage.dart';

class RejectClaimForm extends StatefulWidget {
  final String claim_id;
  final String staff_id;

  const RejectClaimForm({
    super.key,
    required this.claim_id,
    required this.staff_id,
  });

  @override
  State<RejectClaimForm> createState() => _RejectClaimFormState();
}

class _RejectClaimFormState extends State<RejectClaimForm> {
  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color red = Color(0xFFE54842);
  static const Color redDark = Color(0xFFC62828);
  static const Color text = Color(0xFF17213A);
  static const Color muted = Color(0xFF667085);
  static const Color brown = Color(0xFFA4551D);
  static const Color mint = Color(0xFFD7F8E5);
  static const Color darkGreen = Color(0xFF1F6B52);

  final TextEditingController rejectionReasonController = TextEditingController();
  String? validationMessage;

  @override
  void dispose() {
    // OOP METHOD: Dispose controller to avoid memory leak.
    rejectionReasonController.dispose();
    super.dispose();
  }

  // OOP METHOD: This method validates the rejection reason entered by Pusat ADAB.
  bool validateRejectionReason() {
    final reason = rejectionReasonController.text.trim();

    if (reason.isEmpty || reason.length < 10) {
      setState(() {
        validationMessage = 'Please provide a valid rejection reason.';
      });
      return false;
    }

    setState(() => validationMessage = null);
    return true;
  }

  // OOP METHOD: This method submits the rejection decision through controller.
  Future<void> submitRejectClaim(BuildContext context) async {
    if (!validateRejectionReason()) return;

    final controller = Provider.of<CoCurriculumController>(context, listen: false);
    await controller.rejectClaim(
      widget.claim_id,
      widget.staff_id,
      rejectionReasonController.text.trim(),
    );

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClaimSuccessPage(
            message: 'Claim rejected successfully.',
            staff_id: widget.staff_id,
          ),
        ),
      );
    }
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

  // OOP METHOD: This method maps staff to add module page.
  void mapsToAddModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCoCurriculumModulePage(staff_id: widget.staff_id)),
    );
  }

  // OOP METHOD: This method opens staff profile information as a pop-up.
  void displayUserProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Pusat ADAB Profile',
            style: TextStyle(color: text, fontWeight: FontWeight.w900),
          ),
          content: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('PusatAdab')
                .doc(widget.staff_id)
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
                    Center(
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
                    _profileItem('staff_name', readProfileValue(['staff_name'], widget.staff_id)),
                    _profileItem('staff_email', readProfileValue(['staff_email'], widget.staff_id)),
                    _profileItem('department', readProfileValue(['department'], 'Pusat ADAB')),
                    _profileItem('role', readProfileValue(['role'], 'Pusat ADAB')),
                    _profileItem('status', readProfileValue(['status', 'account_status'], 'Active')),
                  ],
                ),
              );
            },
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

  // OOP METHOD: This method shows staff actions from the top-right user button.
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
                leading: const Icon(Icons.add_circle_outline, color: green),
                title: const Text('Add Module', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  mapsToAddModule(context);
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
        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: 'Reject Claim',
                subtitle: 'Alternative flow A1 and E2',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileMenu(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    children: [
                      _formCard(),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 18),
                        _validationBox(validationMessage!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _outlineButton(
                              label: 'Cancel',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rejectButton(
                              label: controller.isLoading ? 'Submitting...' : 'Submit Rejection',
                              onPressed: controller.isLoading
                                  ? () {}
                                  : () => submitRejectClaim(context),
                            ),
                          ),
                        ],
                      ),
                    ],
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
          Text(value, style: const TextStyle(color: text, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _formCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('REJECTION REASON FORM'),
          const SizedBox(height: 16),
          TextField(
            controller: rejectionReasonController,
            maxLines: 5,
            style: const TextStyle(color: text, fontSize: 16, height: 1.35),
            decoration: InputDecoration(
              hintText: 'Example: Module completion evidence is incomplete or record mismatch found.',
              hintStyle: const TextStyle(color: text, fontSize: 16, height: 1.35),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFFFF8A8A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: red, width: 1.4),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 18, 12),
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
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, height: 1.0)),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: brown, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2.4),
    );
  }

  Widget _validationBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE1E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF9B9B)),
      ),
      child: Text(message, style: const TextStyle(color: redDark, fontSize: 16)),
    );
  }

  Widget _rejectButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _outlineButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: text,
          side: const BorderSide(color: Color(0xFFE0E2E6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}
