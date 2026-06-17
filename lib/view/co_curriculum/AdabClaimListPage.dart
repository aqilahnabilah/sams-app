import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'AdabClaimDetailPage.dart';

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
  @override
  void initState() {
    super.initState();

    // Fetch all pending claims when Pusat ADAB opens the claim list page.
    fetchAllClaims();
  }

  // This method retrieves all claims from Firestore.
  // It follows the getAllClaims() process stated in the SDD controller flow.
  void fetchAllClaims() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getAllClaims();
    });
  }

  // This method maps Pusat ADAB to the selected claim detail page.
  void mapsToClaimDetail(
    BuildContext context,
    CoCurriculumClaimModel claim,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdabClaimDetailPage(
          claim: claim,
          staff_id: widget.staff_id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        final pendingClaims = controller.claims
            .where((claim) => claim.claim_status == 'Pending Verification')
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F7A5C),
            elevation: 0,
            title: const Text(
              'Co-curriculum Claims',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.getAllClaims();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: displayClaimList(context, pendingClaims),
                  ),
                ),
        );
      },
    );
  }

  // This method displays the list of pending claims for Pusat ADAB.
  Widget displayClaimList(
    BuildContext context,
    List<CoCurriculumClaimModel> pendingClaims,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        displayHeaderCard(pendingClaims.length),
        const SizedBox(height: 18),
        const Text(
          'Pending Verification',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (pendingClaims.isEmpty)
          displayNoPendingClaim()
        else
          Column(
            children: pendingClaims.map((claim) {
              return displayClaimCard(context, claim);
            }).toList(),
          ),
      ],
    );
  }

  // This method displays summary information for Pusat ADAB.
  Widget displayHeaderCard(int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A5C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.verified_user,
              color: Color(0xFF1F7A5C),
              size: 36,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pusat ADAB Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$pendingCount pending claim(s) require verification.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This method displays message when there is no pending claim.
  Widget displayNoPendingClaim() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 70,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 14),
          Text(
            'No Pending Claim',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There is no co-curriculum claim waiting for verification.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // This method displays each pending claim card.
  Widget displayClaimCard(
    BuildContext context,
    CoCurriculumClaimModel claim,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            mapsToClaimDetail(context, claim);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(
                    Icons.hourglass_top,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.student_id,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${claim.completed_module_count} completed modules',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${formatDate(claim.submission_date)}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // This method formats DateTime into readable date format.
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}