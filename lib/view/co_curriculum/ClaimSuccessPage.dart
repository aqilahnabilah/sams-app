import 'package:flutter/material.dart';

class ClaimSuccessPage extends StatelessWidget {
  final String message;

  const ClaimSuccessPage({
    super.key,
    required this.message,
  });

  // This method returns page title based on claim action.
  String getPageTitle() {
    if (message.toLowerCase().contains('approved')) {
      return 'Claim Approved';
    } else if (message.toLowerCase().contains('rejected')) {
      return 'Claim Rejected';
    } else {
      return 'Claim Submitted';
    }
  }

  // This method returns page description based on claim action.
  String getPageDescription() {
    if (message.toLowerCase().contains('approved')) {
      return 'The student co-curriculum claim has been approved. The system has added 2 co-curriculum credits to the student record.';
    } else if (message.toLowerCase().contains('rejected')) {
      return 'The student co-curriculum claim has been rejected. The student can view the rejection reason from the claim status page.';
    } else {
      return 'Your co-curriculum credit claim has been submitted with Pending Verification status. Please wait for Pusat ADAB to review your claim.';
    }
  }

  // This method returns icon based on claim action.
  IconData getPageIcon() {
    if (message.toLowerCase().contains('approved')) {
      return Icons.verified;
    } else if (message.toLowerCase().contains('rejected')) {
      return Icons.cancel;
    } else {
      return Icons.check_circle;
    }
  }

  // This method returns main color based on claim action.
  Color getMainColor() {
    if (message.toLowerCase().contains('rejected')) {
      return const Color(0xFFC62828);
    } else {
      return const Color(0xFF1F7A5C);
    }
  }

  // This method returns background color based on claim action.
  Color getIconBackgroundColor() {
    if (message.toLowerCase().contains('rejected')) {
      return const Color(0xFFFFEBEE);
    } else {
      return const Color(0xFFE8F5E9);
    }
  }

  // This method maps user back to main menu after the process is completed.
  void mapsToMainMenu(BuildContext context) {
    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: getMainColor(),
        elevation: 0,
        title: Text(
          getPageTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: displaySuccessMessage(context),
      ),
    );
  }

  // This method displays success message after claim submission, approval or rejection.
  Widget displaySuccessMessage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: getIconBackgroundColor(),
            borderRadius: BorderRadius.circular(55),
          ),
          child: Icon(
            getPageIcon(),
            size: 70,
            color: getMainColor(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          getPageTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: getMainColor(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          getPageDescription(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              mapsToMainMenu(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: getMainColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to Main Menu',
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
}