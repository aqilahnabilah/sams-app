import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-313 — Student "Class Check-In" UI with Dark Gradient Theme.
class StudentCheckInPage extends StatelessWidget {
  const StudentCheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentCheckInView();
  }
}

class _StudentCheckInView extends StatefulWidget {
  const _StudentCheckInView();

  @override
  State<_StudentCheckInView> createState() => _StudentCheckInViewState();
}

class _StudentCheckInViewState extends State<_StudentCheckInView> {
  final _codeController = TextEditingController();
  Timer? _gpsPollTimer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGps());
  }

  @override
  void dispose() {
    _gpsPollTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initGps() async {
    final loc = context.read<LocationVerification>();
    if (loc.hasPermission) {
      _isVerifying = true;
      try {
        await loc.verifyCurrentLocation();
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    }

    _gpsPollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false) && !_isVerifying && loc.hasPermission) {
        _isVerifying = true;
        try {
          await loc.verifyCurrentLocation();
        } finally {
          if (mounted) setState(() => _isVerifying = false);
        }
      }
    });
  }

  Future<void> _submitCheckIn() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final studentId = user.userId;

    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final result = await context.read<AttendanceController>().submitAttendance(
          studentId: studentId,
          codeInput: code,
        );

    if (!mounted) return;
    Navigator.pushNamed(context, '/student/attendance-status', arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationVerification>();
    final attendance = context.watch<AttendanceController>();
    final onCampus = location.isOnCampus;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SamsColors.portalGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Class Check-In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Mint Location Status Card (Themed for Dark)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location Status',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        onCampus ? 'On Campus (Verified)' : 'Verification Pending',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: onCampus ? Colors.greenAccent : Colors.amberAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.4), size: 20),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                      
                      // Instruction Labels
                      const Text(
                        'Enter Attendance Code',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provided by your lecturer',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Code Input Box (Themed)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                        ),
                        child: TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Colors.tealAccent,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 24),
                            hintText: 'X79-B',
                            hintStyle: TextStyle(color: Colors.white10, letterSpacing: 4),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: attendance.isSubmitting ? null : _submitCheckIn,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Submit Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Quick Tip Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome_outlined, color: Colors.amberAccent.withOpacity(0.6), size: 24),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Quick Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Make sure you\'re on campus and GPS is enabled before submitting.',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
