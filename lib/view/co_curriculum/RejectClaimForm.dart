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

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> onConfirmReject() async {
    if (formKey.currentState!.validate() == false) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject claim. Please try again.'),
          ),
        );
      }
    }
  }

  void onCancel() {
    Navigator.pop(context);
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
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _buildWarningCard(),
                  const SizedBox(height: 18),
                  _buildReasonForm(),
                  const SizedBox(height: 26),
                  _buildRejectButton(controller),
                  const SizedBox(height: 12),
                  _buildCancelButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF9A9A),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 54,
            color: Color(0xFFC62828),
          ),
          SizedBox(height: 12),
          Text(
            'Reject Co-curriculum Claim',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please provide a clear rejection reason before rejecting this student claim.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7F1D1D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonForm() {
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
      child: TextFormField(
        controller: rejectionReasonController,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Rejection Reason',
          hintText: 'Example: Student has not completed the required modules.',
          alignLabelWithHint: true,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1F7A5C),
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please provide a reason for rejection';
          }

          if (value.trim().length < 10) {
            return 'Rejection reason must be at least 10 characters';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildRejectButton(CoCurriculumController controller) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () {
                onConfirmReject();
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

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onCancel,
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