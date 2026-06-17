import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-317 — Result feedback illustration screen with Dark Gradient Theme.
class AttendanceStatusPage extends StatelessWidget {
  const AttendanceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String status = 'unknown';
    String subjectCode = 'Subject';

    if (args is String) {
      status = args;
    } else if (args is Map<String, dynamic>) {
      status = args['status'] ?? 'unknown';
      subjectCode = args['subjectCode'] ?? 'Subject';
    }

    final isSuccess = status == 'success' || status == 'duplicate';
    final isGpsError = status == 'gps_denied';
    final isLocationError = status == 'outside_campus';
    final isInvalidCode = status == 'invalid_code';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SamsColors.portalGradient,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Container
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSuccess ? Colors.tealAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocationError
                              ? Icons.location_on
                              : (isGpsError
                                  ? Icons.warning_amber_rounded
                                  : (isInvalidCode || !isSuccess ? Icons.close : Icons.check)),
                          color: isSuccess ? Colors.tealAccent : Colors.redAccent,
                          size: 64,
                        ),
                      ),
                      if (isLocationError)
                        const Icon(
                          Icons.cancel,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    isInvalidCode
                        ? 'Invalid Code'
                        : (isLocationError
                            ? 'Location Error'
                            : (isGpsError
                                ? 'Permission Required'
                                : (isSuccess ? 'Success!' : _getErrorTitle(status)))),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Badge
                  if (isSuccess || isGpsError || isLocationError || isInvalidCode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? Colors.tealAccent.withOpacity(0.1)
                            : Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSuccess ? Colors.tealAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isSuccess
                            ? 'ATTENDANCE RECORDED'
                            : (isInvalidCode
                                ? 'VERIFICATION FAILED'
                                : (isLocationError ? 'NOT ON CAMPUS' : 'GPS ACCESS NEEDED')),
                        style: TextStyle(
                          color: isSuccess ? Colors.tealAccent : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Message
                  if (isSuccess)
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'Your attendance for '),
                          TextSpan(
                            text: subjectCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const TextSpan(text: ' has\nbeen recorded as '),
                          const TextSpan(
                            text: 'Present',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    )
                  else
                    Text(
                      isInvalidCode
                          ? 'The class code you entered is incorrect or has expired. Please try again.'
                          : (isLocationError
                              ? 'Check-in failed. You must be physically on the UMPSA campus to record your attendance.'
                              : (isGpsError
                                  ? 'Location access is required to check in. Please enable GPS in your device settings.'
                                  : _getErrorMessage(status))),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isGpsError) {
                          final loc = context.read<LocationVerification>();
                          await loc.checkGPSPermission();
                          if (!loc.hasPermission) {
                            await Geolocator.openAppSettings();
                          }
                        } else if (isSuccess) {
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName('/student/check-in'),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccess ? Colors.teal.shade400 : Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isInvalidCode
                            ? 'Retry'
                            : (isLocationError
                                ? 'Close'
                                : (isGpsError ? 'Go to Settings' : (isSuccess ? 'Done' : 'Back'))),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorTitle(String status) {
    switch (status) {
      case 'gps_denied': return 'GPS Error';
      case 'outside_campus': return 'Location Alert';
      case 'invalid_code': return 'Invalid Code';
      case 'db_error': return 'System Error';
      default: return 'Oops!';
    }
  }

  String _getErrorMessage(String status) {
    switch (status) {
      case 'gps_denied': return 'Please enable GPS to check in.';
      case 'outside_campus': return 'You must be on campus to submit attendance.';
      case 'invalid_code': return 'The code is incorrect or expired.';
      case 'db_error': return 'Database connection failed.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
