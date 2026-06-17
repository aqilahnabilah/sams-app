import 'package:flutter/material.dart';

class ClaimSuccessPage extends StatelessWidget {
  final String message;

  const ClaimSuccessPage({
    super.key,
    required this.message,
  });

  String getTitle() {
    if (message.toLowerCase().contains('approved')) {
      return 'Claim Approved';
    } else if (message.toLowerCase().contains('rejected')) {
      return 'Claim Rejected';
    } else {
      return 'Claim Submitted';
    }
  }

  String getDescription() {
    if (message.toLowerCase().contains('approved')) {
      return 'The student co-curriculum claim has been approved. The system has added 2 co-curriculum credits to the student record.';
    } else if (message.toLowerCase().contains('rejected')) {
      return 'The student co-curriculum claim has been rejected. The student can view the rejection reason from the claim status page.';
    } else {
      return 'Your co-curriculum credit claim has been submitted with Pending Verification status. Please wait for Pusat ADAB to review your claim.';
    }
  }

  IconData getIcon() {
    if (message.toLowerCase().contains('approved')) {
      return Icons.verified;
    } else if (message.toLowerCase().contains('rejected')) {
      return Icons.cancel;
    } else {
      return Icons.check_circle;
    }
  }

  Color getMainColor() {
    if (message.toLowerCase().contains('approved')) {
      return const Color(0xFF1F7A5C);
    } else if (message.toLowerCase().contains('rejected')) {
      return const Color(0xFFC62828);
    } else {
      return const Color(0xFF1F7A5C);
    }
  }

  Color getBackgroundColor() {
    if (message.toLowerCase().contains('rejected')) {
      return const Color(0xFFFFEBEE);
    } else {
      return const Color(0xFFE8F5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = getMainColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        title: Text(
          getTitle(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: getBackgroundColor(),
                borderRadius: BorderRadius.circular(55),
              ),
              child: Icon(
                getIcon(),
                size: 70,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTitle(),
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
                color: mainColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getDescription(),
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
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
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
        ),
      ),
    );
  }
}