import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getClaimStatus(widget.student_id);
    });
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
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: controller.claim == null
                      ? _buildNoClaimCard()
                      : _buildClaimStatusCard(controller),
                ),
        );
      },
    );
  }

  Widget _buildNoClaimCard() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 60,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 16),
            Text(
              'No Claim Submitted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have not submitted any co-curriculum credit claim yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimStatusCard(CoCurriculumController controller) {
    final claim = controller.claim!;
    final statusColor = _getStatusColor(claim.claim_status);
    final statusIcon = _getStatusIcon(claim.claim_status);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
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
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  statusIcon,
                  size: 46,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                claim.claim_status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusMessage(claim.claim_status),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _detailRow(
                title: 'Student ID',
                value: claim.student_id,
              ),
              _detailRow(
                title: 'Completed Modules',
                value: '${claim.completed_module_count} / 4',
              ),
              _detailRow(
                title: 'Credit Awarded',
                value: '${claim.credit_awarded} Credits',
              ),
              _detailRow(
                title: 'Submission Date',
                value:
                    '${claim.submission_date.day}/${claim.submission_date.month}/${claim.submission_date.year}',
              ),
              if (claim.verified_by != null)
                _detailRow(
                  title: 'Verified By',
                  value: claim.verified_by!,
                ),
              if (claim.rejection_reason != null &&
                  claim.rejection_reason!.isNotEmpty)
                _detailRow(
                  title: 'Rejection Reason',
                  value: claim.rejection_reason!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F7A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow({
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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

  Color _getStatusColor(String status) {
    if (status == 'Approved') {
      return const Color(0xFF2E7D32);
    } else if (status == 'Rejected') {
      return const Color(0xFFC62828);
    } else {
      return const Color(0xFFE65100);
    }
  }

  IconData _getStatusIcon(String status) {
    if (status == 'Approved') {
      return Icons.check_circle;
    } else if (status == 'Rejected') {
      return Icons.cancel;
    } else {
      return Icons.hourglass_top;
    }
  }

  String _getStatusMessage(String status) {
    if (status == 'Approved') {
      return 'Your co-curriculum claim has been approved by Pusat ADAB.';
    } else if (status == 'Rejected') {
      return 'Your co-curriculum claim has been rejected. Please check the rejection reason.';
    } else {
      return 'Your co-curriculum claim is waiting for verification by Pusat ADAB.';
    }
  }
}