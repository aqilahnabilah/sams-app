import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// Redesigned GPS permission gate for SAMS Attendance.
class GPSPermissionPage extends StatefulWidget {
  const GPSPermissionPage({super.key});

  @override
  State<GPSPermissionPage> createState() => _GPSPermissionPageState();
}

class _GPSPermissionPageState extends State<GPSPermissionPage> {
  bool _isRequested = false;

  Future<void> _handlePermissionRequest() async {
    setState(() => _isRequested = true);
    final loc = context.read<LocationVerification>();
    
    // 1. Check/Request Permission
    final granted = await loc.checkGPSPermission();

    if (!mounted) return;

    if (granted) {
      // 2. If granted, immediately attempt to verify location
      final success = await loc.verifyCurrentLocation();
      if (mounted) {
        // Navigate to check-in page
        Navigator.pushReplacementNamed(context, '/student/check-in');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationVerification>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                        'Location Access',
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Visual Icon
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 80,
                          color: Colors.tealAccent,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      const Text(
                        'Enable GPS to Check-In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'To ensure fair attendance, SAMS requires your GPS location to verify that you are physically present on campus during the session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Error Message if denied
                      if (_isRequested && !location.hasPermission)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location.statusMessage ?? 'Location access is required.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => Geolocator.openAppSettings(),
                                      child: const Text(
                                        'Open Device Settings',
                                        style: TextStyle(
                                          color: Colors.tealAccent,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: location.isChecking ? null : _handlePermissionRequest,
                          icon: location.isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.near_me),
                          label: Text(
                            location.hasPermission ? 'Continue' : 'Allow Access',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      
                      if (location.hasPermission)
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/student/check-in'),
                          child: const Text('Already granted? Click here', style: TextStyle(color: Colors.tealAccent)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
