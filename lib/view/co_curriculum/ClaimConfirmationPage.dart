import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'ClaimSuccessPage.dart';

class ClaimConfirmationPage extends StatelessWidget {
  final String student_id;
  final int completed_module_count;

  const ClaimConfirmationPage({
    super.key,
    required this.student_id,
    required this.completed_module_count,
  });

  Future<void> submitCoCurriculumClaim(BuildContext context) async {
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
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildIcon(),
                const SizedBox(height: 20),
                _buildConfirmationCard(),
                const SizedBox(height: 20),
                _buildClaimSummary(),
                const SizedBox(height: 30),
                _buildConfirmButton(context, controller),
                const SizedBox(height: 12),
                _buildCancelButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(45),
      ),
      child: const Icon(
        Icons.assignment_turned_in,
        size: 48,
        color: Color(0xFF1F7A5C),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: const Column(
        children: [
          Text(
            'Confirm Co-curriculum Claim',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please confirm that you want to submit your co-curriculum credit claim for verification by Pusat ADAB.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Claim Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
            title: 'Student ID',
            value: student_id,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            title: 'Completed Modules',
            value: '$completed_module_count / 4',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            title: 'Credit Awarded',
            value: '2 Credits',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            title: 'Claim Status',
            value: 'Pending Verification',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 14,
          ),
        ),
        Flexible(
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
    );
  }

  Widget _buildConfirmButton(
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
                submitCoCurriculumClaim(context);
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
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF1F7A5C),
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
    );
  }
}