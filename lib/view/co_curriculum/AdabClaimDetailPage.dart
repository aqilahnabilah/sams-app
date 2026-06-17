import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimSuccessPage.dart';
import 'AdabClaimListPage.dart';
import 'AddCoCurriculumModulePage.dart';
import 'RejectClaimForm.dart';

class AdabClaimDetailPage extends StatefulWidget {
  final CoCurriculumClaimModel claim;
  final String staff_id;

  const AdabClaimDetailPage({
    super.key,
    required this.claim,
    required this.staff_id,
  });

  @override
  State<AdabClaimDetailPage> createState() => _AdabClaimDetailPageState();
}

class _AdabClaimDetailPageState extends State<AdabClaimDetailPage> {
  static const Color bg = Color(0xFFFFFBF2);
  static const Color green = Color(0xFF459B7B);
  static const Color darkGreen = Color(0xFF22745A);
  static const Color mint = Color(0xFFD8F7E5);
  static const Color text = Color(0xFF17213A);
  static const Color muted = Color(0xFF667085);
  static const Color brown = Color(0xFFA4551D);

  bool isApproving = false;

  @override
  void initState() {
    super.initState();
    fetchClaimDetail();
    fetchCompletedModules();
  }

  // OOP METHOD: This method retrieves the selected claim detail.
  void fetchClaimDetail() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(context, listen: false)
          .getClaimDetail(widget.claim.claim_id);
    });
  }

  // OOP METHOD: This method retrieves completed module records for verification.
  void fetchCompletedModules() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(context, listen: false)
          .getStudentRecords(widget.claim.student_id);
    });
  }

  // OOP METHOD: This method approves the claim and records 2 credits.
  Future<void> approveSelectedClaim(BuildContext context) async {
    setState(() => isApproving = true);

    try {
      final controller = Provider.of<CoCurriculumController>(context, listen: false);
      await controller.approveClaim(
        widget.claim.claim_id,
        widget.staff_id,
        widget.claim.student_id,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimSuccessPage(
              message: 'Claim approved successfully.',
              staff_id: widget.staff_id,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }

    if (mounted) setState(() => isApproving = false);
  }

  // OOP METHOD: This method maps Pusat ADAB to the rejection form.
  void mapsToRejectClaimForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RejectClaimForm(
          claim_id: widget.claim.claim_id,
          staff_id: widget.staff_id,
        ),
      ),
    );
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

  // OOP METHOD: This method maps staff back to add module screen.
  void mapsToAddModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCoCurriculumModulePage(staff_id: widget.staff_id)),
    );
  }

  // OOP METHOD: This method opens Pusat ADAB profile information as a pop-up.
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
                    _detailRow('staff_name', readProfileValue(['staff_name'], widget.staff_id)),
                    _detailRow('staff_email', readProfileValue(['staff_email'], widget.staff_id)),
                    _detailRow('department', readProfileValue(['department'], 'Pusat ADAB')),
                    _detailRow('role', readProfileValue(['role'], 'Pusat ADAB')),
                    _detailRow('status', readProfileValue(['status', 'account_status'], 'Active')),
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
        final student = controller.student;
        final completedRecords = controller.records.where((record) => record.isCompleted()).toList();
        final displayRecords = completedRecords.take(3).toList();
        final remaining = completedRecords.length - displayRecords.length;

        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: 'Review Claim',
                subtitle: 'Student record and claim details',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileMenu(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: Column(
                          children: [
                            _studentCard(
                              name: student?.full_name.isNotEmpty == true
                                  ? student!.full_name
                                  : widget.claim.student_id,
                              matric: widget.claim.student_id,
                            ),
                            const SizedBox(height: 14),
                            _moduleCard(controller, displayRecords, remaining),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _primaryButton(
                                    label: isApproving ? 'Approving...' : 'Approve',
                                    onPressed: isApproving
                                        ? () {}
                                        : () => approveSelectedClaim(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _outlineButton(
                                    label: 'Reject',
                                    onPressed: () => mapsToRejectClaimForm(context),
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

  Widget _topHeader({
    required String title,
    required String subtitle,
    required VoidCallback onBackTap,
    required VoidCallback onAvatarTap,
  }) {
    return Container(
      width: double.infinity,
      height: 125,
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
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.0)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _studentCard({required String name, required String matric}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('STUDENT DETAILS'),
          const SizedBox(height: 14),
          _detailRow('Student Name', name),
          _detailRow('Matric No.', matric),
          _detailRow('Claim Type', 'Co-curriculum Credit'),
        ],
      ),
    );
  }

  Widget _moduleCard(CoCurriculumController controller, List<dynamic> displayRecords, int remaining) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('COMPLETED MODULE RECORDS'),
          const SizedBox(height: 12),
          if (displayRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: _innerDecoration(),
              child: const Text('No completed module records found.', style: TextStyle(color: muted)),
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
                style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600),
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
                Text(moduleName, style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(category, style: const TextStyle(color: muted, fontSize: 12)),
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
            child: const Text('Completed', style: TextStyle(color: darkGreen, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 14))),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800),
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
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5)),
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
      style: const TextStyle(color: brown, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.0),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
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
