import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'AdabClaimDetailPage.dart';
import 'AddCoCurriculumModulePage.dart';

class AdabClaimListPage extends StatefulWidget {
  final String staff_id;

  const AdabClaimListPage({
    super.key,
    required this.staff_id,
  });

  @override
  State<AdabClaimListPage> createState() => _AdabClaimListPageState();
}

class _AdabClaimListPageState extends State<AdabClaimListPage> {
  CoCurriculumClaimModel? selectedClaim;

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
    fetchAdabDashboardData();
  }

  // OOP METHOD: This method retrieves claim queue and module data for Pusat ADAB.
  void fetchAdabDashboardData() {
    Future.microtask(() async {
      final controller = Provider.of<CoCurriculumController>(context, listen: false);
      await controller.getAllClaims();
      await controller.getAvailableModules();
    });
  }

  // OOP METHOD: This method maps Pusat ADAB to add module screen.
  void mapsToAddModule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCoCurriculumModulePage(staff_id: widget.staff_id),
      ),
    ).then((value) => fetchAdabDashboardData());
  }

  // OOP METHOD: This method maps Pusat ADAB to selected claim detail screen.
  void mapsToClaimDetail(BuildContext context, CoCurriculumClaimModel claim) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdabClaimDetailPage(
          claim: claim,
          staff_id: widget.staff_id,
        ),
      ),
    ).then((value) => fetchAdabDashboardData());
  }

  // OOP METHOD: This method selects one pending claim from the queue before opening detail.
  void selectClaim(CoCurriculumClaimModel claim) {
    setState(() {
      selectedClaim = claim;
    });
  }

  // OOP METHOD: This method opens the selected pending claim detail safely.
  void openSelectedClaimDetail(
    BuildContext context,
    List<CoCurriculumClaimModel> pendingClaims,
  ) {
    CoCurriculumClaimModel? claimToOpen = selectedClaim;

    final selectedStillPending = claimToOpen != null &&
        pendingClaims.any((claim) => claim.claim_id == claimToOpen!.claim_id);

    if (!selectedStillPending && pendingClaims.isNotEmpty) {
      claimToOpen = pendingClaims.first;
    }

    if (claimToOpen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending claim to open.')),
      );
      return;
    }

    mapsToClaimDetail(context, claimToOpen);
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
                    _infoRow('staff_name', readProfileValue(['staff_name'], widget.staff_id)),
                    _infoRow('staff_email', readProfileValue(['staff_email'], widget.staff_id)),
                    _infoRow('department', readProfileValue(['department'], 'Pusat ADAB')),
                    _infoRow('role', readProfileValue(['role'], 'Pusat ADAB')),
                    _infoRow('status', readProfileValue(['status', 'account_status'], 'Active')),
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
        final pendingClaims = controller.claims
            .where((claim) => claim.claim_status == 'Pending Verification')
            .toList();
        final approvedToday = controller.claims.where((claim) {
          final date = claim.verification_date;
          if (date == null || claim.claim_status != 'Approved') return false;
          final now = DateTime.now();
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).length;

        return Scaffold(
          backgroundColor: bg,
          
          body: Column(
            children: [
              _topHeader(
                title: 'Co-curriculum Verification',
                subtitle: 'Pending claims list',
                onBackTap: () => Navigator.maybePop(context),
                onAvatarTap: () => displayProfileDialog(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : RefreshIndicator(
                        color: green,
                        onRefresh: () async => fetchAdabDashboardData(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          child: Column(
                            children: [
                              _summaryCard(pendingClaims.length, approvedToday),
                              const SizedBox(height: 14),
                              _claimQueueCard(context, pendingClaims),
                              const SizedBox(height: 14),
                              _primaryButton(
                                label: 'Open Claim Details',
                                onPressed: () => openSelectedClaimDetail(
                                  context,
                                  pendingClaims,
                                ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
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

  Widget _summaryCard(int pendingCount, int approvedToday) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PENDING VERIFICATION'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numberBox('Pending Claims', '$pendingCount', yellow, const Color(0xFFF2C94C), const Color(0xFFC75E00))),
              const SizedBox(width: 10),
              Expanded(child: _numberBox('Approved Today', '$approvedToday', mint, const Color(0xFF77E5A6), darkGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _claimQueueCard(BuildContext context, List<CoCurriculumClaimModel> pendingClaims) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CLAIM QUEUE'),
          const SizedBox(height: 12),
          if (pendingClaims.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: _innerDecoration(),
              child: const Text(
                'No pending co-curriculum claim at the moment.',
                style: TextStyle(color: muted),
              ),
            )
          else
            ...pendingClaims.take(3).map((claim) {
              final effectiveSelectedId = selectedClaim?.claim_id ?? pendingClaims.first.claim_id;
              final isSelected = effectiveSelectedId == claim.claim_id;
              return GestureDetector(
                onTap: () => selectClaim(claim),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                  decoration: BoxDecoration(
                    color: isSelected ? yellow : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFFF2C94C) : const Color(0xFFE6E7EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.student_id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${claim.completed_module_count} completed modules • Pending',
                        style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _numberBox(String label, String value, Color color, Color border, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w900)),
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
      borderRadius: BorderRadius.circular(16),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: text, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
