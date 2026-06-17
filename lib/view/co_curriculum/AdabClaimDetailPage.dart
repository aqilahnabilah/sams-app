import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'ClaimSuccessPage.dart';
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
  @override
  void initState() {
    super.initState();

    // Fetch selected claim detail and student completed modules when page opens.
    fetchClaimDetail();
    fetchCompletedModules();
  }

  // This method retrieves selected claim detail from Firestore.
  // It follows the getClaimDetail(claim_id) method stated in the SDD.
  void fetchClaimDetail() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getClaimDetail(widget.claim.claim_id);
    });
  }

  // This method retrieves student co-curriculum completed module records.
  // It allows Pusat ADAB to review completed modules before approval.
  void fetchCompletedModules() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getStudentRecords(widget.claim.student_id);
    });
  }

  // This method approves the selected co-curriculum claim.
  // It calls the controller to update claim status and add 2 credits to student record.
  Future<void> approveSelectedClaim(BuildContext context) async {
    if (widget.claim.completed_module_count < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Claim cannot be approved because completed module is less than 4.',
          ),
        ),
      );
      return;
    }

    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    try {
      await controller.approveClaim(
        widget.claim.claim_id,
        widget.staff_id,
        widget.claim.student_id,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ClaimSuccessPage(
              message: 'Claim approved successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to approve claim. Please try again.',
            ),
          ),
        );
      }
    }
  }

  // This method maps Pusat ADAB to the reject claim form.
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F7A5C),
            elevation: 0,
            title: const Text(
              'Review Claim',
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
                    await controller.getClaimDetail(widget.claim.claim_id);
                    await controller.getStudentRecords(widget.claim.student_id);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: displayClaimDetail(context, controller),
                  ),
                ),
        );
      },
    );
  }

  // This method displays all claim details for Pusat ADAB verification.
  Widget displayClaimDetail(
    BuildContext context,
    CoCurriculumController controller,
  ) {
    return Column(
      children: [
        displayStatusHeader(),
        const SizedBox(height: 16),
        displayClaimInformation(),
        const SizedBox(height: 16),
        displayCompletedModules(controller),
        const SizedBox(height: 16),
        displayVerificationNote(),
        const SizedBox(height: 24),
        displayApproveButton(context, controller),
        const SizedBox(height: 12),
        displayRejectButton(context),
      ],
    );
  }

  // This method displays pending verification status.
  Widget displayStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB74D),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user,
            size: 52,
            color: Color(0xFFE65100),
          ),
          SizedBox(height: 12),
          Text(
            'Pending Verification',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please review the student claim information and completed modules before approval or rejection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF92400E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // This method displays selected claim information.
  Widget displayClaimInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Claim Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          displayInformationRow(
            title: 'Claim ID',
            value: widget.claim.claim_id,
          ),
          displayInformationRow(
            title: 'Student ID',
            value: widget.claim.student_id,
          ),
          displayInformationRow(
            title: 'Completed Modules',
            value: '${widget.claim.completed_module_count} / 4',
          ),
          displayInformationRow(
            title: 'Claim Status',
            value: widget.claim.claim_status,
          ),
          displayInformationRow(
            title: 'Credit Awarded',
            value: '${widget.claim.credit_awarded} Credits',
          ),
          displayInformationRow(
            title: 'Submission Date',
            value: formatDate(widget.claim.submission_date),
          ),
        ],
      ),
    );
  }

  // This method displays student completed modules for verification.
  Widget displayCompletedModules(CoCurriculumController controller) {
    final completedRecords = controller.records
        .where((record) => record.isCompleted())
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Modules',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          if (completedRecords.isEmpty)
            const Text(
              'No completed module record found.',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            )
          else
            Column(
              children: completedRecords.map((record) {
                final module = controller.modules[record.module_id];

                final moduleName = module?.module_name ?? record.module_id;
                final moduleCategory =
                    module?.module_category ?? 'Co-curriculum Module';

                return displayCompletedModuleCard(
                  moduleName: moduleName,
                  moduleCategory: moduleCategory,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // This method displays each completed module card.
  Widget displayCompletedModuleCard({
    required String moduleName,
    required String moduleCategory,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(
              Icons.check,
              color: Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Category: $moduleCategory',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // This method displays verification rule for Pusat ADAB.
  Widget displayVerificationNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF1D4ED8),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Only claims with at least 4 completed co-curriculum modules can be approved. Approved claims will add 2 co-curriculum credits to the student record.',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method displays each claim information row.
  Widget displayInformationRow({
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method displays approve claim button.
  Widget displayApproveButton(
    BuildContext context,
    CoCurriculumController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () {
                approveSelectedClaim(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F7A5C),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: controller.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Approve Claim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // This method displays reject claim button.
  Widget displayRejectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          mapsToRejectClaimForm(context);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFC62828),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Reject Claim',
          style: TextStyle(
            color: Color(0xFFC62828),
            fontWeight: FontWeight.bold,
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