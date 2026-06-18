import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'ClaimSuccessPage.dart';

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
  final TextEditingController rejectionReasonController =
      TextEditingController();

  @override
  void dispose() {
    // Dispose controller to avoid memory leak.
    rejectionReasonController.dispose();
    super.dispose();
  }

  // This method validates the rejection reason entered by Pusat ADAB.
  bool validateRejectionReason() {
    final reason = rejectionReasonController.text.trim();

    if (reason.isEmpty) {
      showMessage('Please enter rejection reason.');
      return false;
    }

    if (reason.length < 10) {
      showMessage('Rejection reason must be at least 10 characters.');
      return false;
    }

    return true;
  }

  // This method submits the rejection decision.
  // It calls the controller to update claim status as Rejected.
  Future<void> submitRejectClaim(BuildContext context) async {
    if (!validateRejectionReason()) {
      return;
    }

    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    try {
      await controller.rejectClaim(
        widget.claim_id,
        widget.staff_id,
        rejectionReasonController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ClaimSuccessPage(
              message: 'Claim rejected successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showMessage('Failed to reject claim. Please try again.');
      }
    }
  }

  // This method displays message using SnackBar.
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
            backgroundColor: const Color(0xFFC62828),
            elevation: 0,
            title: const Text(
              'Reject Claim',
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
            child: displayRejectClaimForm(context, controller),
          ),
        );
      },
    );
  }

  // This method displays the reject claim form.
  Widget displayRejectClaimForm(
    BuildContext context,
    CoCurriculumController controller,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        displayHeaderCard(),
        const SizedBox(height: 18),
        displayReasonInput(),
        const SizedBox(height: 18),
        displayRejectNotice(),
        const SizedBox(height: 28),
        displaySubmitButton(context, controller),
        const SizedBox(height: 12),
        displayCancelButton(context),
      ],
    );
  }

  // This method displays rejection page header.
  Widget displayHeaderCard() {
    return Container(
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
      child: const Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFFFEBEE),
            child: Icon(
              Icons.cancel,
              size: 52,
              color: Color(0xFFC62828),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Reject Co-curriculum Claim',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please enter a clear rejection reason. The student can view this reason from the claim status page.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // This method displays rejection reason input field.
  Widget displayReasonInput() {
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
            'Rejection Reason',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rejectionReasonController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter rejection reason here...',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method displays rejection notice for Pusat ADAB.
  Widget displayRejectNotice() {
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: Color(0xFFC62828),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Once rejected, the claim status will be updated as Rejected and the rejection reason will be stored in the database.',
              style: TextStyle(
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

  // This method displays confirm reject button.
  Widget displaySubmitButton(
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
                submitRejectClaim(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
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
                'Confirm Reject Claim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // This method displays cancel button.
  Widget displayCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFC62828),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Color(0xFFC62828),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}