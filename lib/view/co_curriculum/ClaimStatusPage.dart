import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';

class ClaimStatusPage extends StatefulWidget {
  final String student_id;

  const ClaimStatusPage({
    super.key,
    required this.student_id,
  });

  @override
  State<ClaimStatusPage> createState() => _ClaimStatusPageState();
}

class _ClaimStatusPageState extends State<ClaimStatusPage> {
  @override
  void initState() {
    super.initState();

    // Fetch claim status when the page is opened.
    fetchClaimStatus();
  }

  // This method retrieves the latest claim status from Firestore.
  // It follows the Boundary/View responsibility stated in the SDD.
  void fetchClaimStatus() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getClaimStatus(widget.student_id);
    });
  }

  // This method converts nullable text values into safe display text.
  String safeText(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
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
              'Claim Status',
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
                    await controller.getClaimStatus(widget.student_id);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: displayClaimStatus(controller),
                  ),
                ),
        );
      },
    );
  }

  // This method displays the claim status to the student.
  Widget displayClaimStatus(CoCurriculumController controller) {
    final claim = controller.claim;

    if (claim == null) {
      return displayNoClaimRecord();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        displayStatusHeader(claim),
        const SizedBox(height: 18),
        displayClaimInformation(claim),
        const SizedBox(height: 18),
        displayStatusDescription(claim),
        const SizedBox(height: 18),
        displayRejectionReason(claim),
      ],
    );
  }

  // This method displays message when no claim record exists.
  Widget displayNoClaimRecord() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_late_outlined,
            size: 80,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Claim Record Found',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have not submitted any co-curriculum claim yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
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
                'Back to Co-curriculum Page',
                style: TextStyle(
                  color: Color(0xFF1F7A5C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method displays status icon and status title.
  Widget displayStatusHeader(CoCurriculumClaimModel claim) {
    final statusColor = getStatusColor(claim.claim_status);
    final backgroundColor = getStatusBackgroundColor(claim.claim_status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            getStatusIcon(claim.claim_status),
            size: 70,
            color: statusColor,
          ),
          const SizedBox(height: 14),
          Text(
            claim.claim_status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getStatusMessage(claim.claim_status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // This method displays detailed claim information.
  Widget displayClaimInformation(CoCurriculumClaimModel claim) {
    final String verifiedBy = safeText(claim.verified_by);
    final DateTime? verificationDate = claim.verification_date;

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
          const SizedBox(height: 14),
          displayInformationRow(
            title: 'Claim ID',
            value: claim.claim_id,
          ),
          displayInformationRow(
            title: 'Student ID',
            value: claim.student_id,
          ),
          displayInformationRow(
            title: 'Completed Modules',
            value: '${claim.completed_module_count} / 4',
          ),
          displayInformationRow(
            title: 'Credit Awarded',
            value: '${claim.credit_awarded} Credits',
          ),
          displayInformationRow(
            title: 'Submission Date',
            value: formatDate(claim.submission_date),
          ),
          displayInformationRow(
            title: 'Verified By',
            value: verifiedBy.isNotEmpty ? verifiedBy : '-',
          ),
          displayInformationRow(
            title: 'Verification Date',
            value: verificationDate != null ? formatDate(verificationDate) : '-',
          ),
        ],
      ),
    );
  }

  // This method displays the meaning of the current claim status.
  Widget displayStatusDescription(CoCurriculumClaimModel claim) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getDetailedStatusDescription(claim.claim_status),
              style: const TextStyle(
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

  // This method displays rejection reason if the claim is rejected.
  Widget displayRejectionReason(CoCurriculumClaimModel claim) {
    if (claim.claim_status != 'Rejected') {
      return const SizedBox.shrink();
    }

    final String rejectionReason = safeText(claim.rejection_reason);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rejectionReason.isNotEmpty
                  ? rejectionReason
                  : 'No rejection reason provided.',
              style: const TextStyle(
                color: Color(0xFFC62828),
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

  // This method returns status icon based on claim_status.
  IconData getStatusIcon(String status) {
    if (status == 'Approved') {
      return Icons.verified;
    } else if (status == 'Rejected') {
      return Icons.cancel;
    } else {
      return Icons.hourglass_top;
    }
  }

  // This method returns status color based on claim_status.
  Color getStatusColor(String status) {
    if (status == 'Approved') {
      return const Color(0xFF2E7D32);
    } else if (status == 'Rejected') {
      return const Color(0xFFC62828);
    } else {
      return const Color(0xFFE65100);
    }
  }

  // This method returns background color based on claim_status.
  Color getStatusBackgroundColor(String status) {
    if (status == 'Approved') {
      return const Color(0xFFE8F5E9);
    } else if (status == 'Rejected') {
      return const Color(0xFFFFEBEE);
    } else {
      return const Color(0xFFFFF3E0);
    }
  }

  // This method returns short status message.
  String getStatusMessage(String status) {
    if (status == 'Approved') {
      return 'Your co-curriculum claim has been approved.';
    } else if (status == 'Rejected') {
      return 'Your co-curriculum claim has been rejected.';
    } else {
      return 'Your claim is waiting for Pusat ADAB verification.';
    }
  }

  // This method returns detailed status description.
  String getDetailedStatusDescription(String status) {
    if (status == 'Approved') {
      return 'The claim has been verified by Pusat ADAB. The system has added 2 co-curriculum credits to your student record.';
    } else if (status == 'Rejected') {
      return 'The claim has been rejected by Pusat ADAB. Please review the rejection reason and contact Pusat ADAB if further clarification is required.';
    } else {
      return 'The claim has been submitted successfully and is currently pending verification by Pusat ADAB.';
    }
  }

  // This method formats DateTime into readable date format.
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}