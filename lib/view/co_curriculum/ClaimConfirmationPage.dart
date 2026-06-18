import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'ClaimSuccessPage.dart';

class ClaimConfirmationPage extends StatelessWidget {
  final String student_id;
  final String full_name;

  const ClaimConfirmationPage({
    super.key,
    required this.student_id,
    required this.full_name,
  });

  // This method submits the co-curriculum claim request.
  // It calls the controller to check eligibility, duplicate claim and save claim data.
  Future<void> submitClaimRequest(BuildContext context) async {
    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    final result = await controller.submitClaim(student_id);

    if (context.mounted) {
      if (result == 'Claim submitted successfully.') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimSuccessPage(
              message: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
          ),
        );
      }
    }
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
              'Claim Confirmation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: displayClaimConfirmation(context, controller),
          ),
        );
      },
    );
  }

  // This method displays claim confirmation details before submission.
  Widget displayClaimConfirmation(
    BuildContext context,
    CoCurriculumController controller,
  ) {
    final completedCount = controller.getCompletedModuleCount();
    final isEligible = completedCount >= 4;

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: isEligible
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                child: Icon(
                  isEligible ? Icons.check_circle : Icons.warning,
                  size: 52,
                  color: isEligible
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isEligible
                    ? 'Confirm Co-curriculum Claim'
                    : 'Claim Requirement Not Met',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isEligible
                    ? 'Please confirm your claim submission. The claim will be sent to Pusat ADAB for verification.'
                    : 'You must complete at least 4 co-curriculum modules before submitting a claim.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        displayClaimSummary(completedCount),
        const SizedBox(height: 18),
        displayClaimNotice(),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isLoading || !isEligible
                ? null
                : () {
                    submitClaimRequest(context);
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
                    'Confirm Submit Claim',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1F7A5C),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF1F7A5C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // This method displays student claim summary before submission.
  Widget displayClaimSummary(int completedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Claim Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          displaySummaryRow(
            title: 'Student ID',
            value: student_id,
          ),
          displaySummaryRow(
            title: 'Student Name',
            value: full_name,
          ),
          displaySummaryRow(
            title: 'Completed Modules',
            value: '$completedCount / 4',
          ),
          displaySummaryRow(
            title: 'Claim Status',
            value: 'Pending Verification',
          ),
          displaySummaryRow(
            title: 'Credit Awarded',
            value: '2 Credits',
          ),
        ],
      ),
    );
  }

  // This method displays important claim notice to the student.
  Widget displayClaimNotice() {
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
              'After submission, the claim status will be set as Pending Verification. Pusat ADAB will review the claim before approving or rejecting it.',
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

  // This method displays each summary item in the claim summary card.
  Widget displaySummaryRow({
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
}