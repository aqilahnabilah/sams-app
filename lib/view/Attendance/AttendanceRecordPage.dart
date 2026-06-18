import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-312 — Real-time live check-in list with integrated controls and Dark Gradient Theme.
class AttendanceRecordPage extends StatefulWidget {
  const AttendanceRecordPage({super.key});

  @override
  State<AttendanceRecordPage> createState() => _AttendanceRecordPageState();
}

class _AttendanceRecordPageState extends State<AttendanceRecordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ModalRoute.of(context)?.settings.arguments;
      if (session is ClassSessionModel) {
        context.read<AttendanceController>().listenToSessionAttendance(session.classSessionId);
        context.read<ClassCodeController>().fetchActiveCode(session.classSessionId);
      }
    });
  }

  @override
  void dispose() {
    context.read<AttendanceController>().stopListeningToSessionAttendance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ModalRoute.of(context)?.settings.arguments as ClassSessionModel?;
    final attendance = context.watch<AttendanceController>();
    final codeController = context.watch<ClassCodeController>();
    
    final records = attendance.sessionRecords;
    final timeFormat = DateFormat('hh:mm a');
    final isOpen = codeController.sessionStatus == 'Open';

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session selected', style: TextStyle(color: Colors.white70))));
    }

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
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Live Attendance',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Top Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      '${records.length}',
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 64, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Students Present'.toUpperCase(),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${session.subjectCode} • Sec ${session.classSection}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              // QUICK CONTROLS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _miniToggle(
                      label: 'LOCATION',
                      value: codeController.requiresLocation,
                      onChanged: (_) => codeController.toggleLocationRequirement(session.classSessionId),
                    ),
                    const SizedBox(width: 12),
                    _miniToggle(
                      label: 'SESSION',
                      value: isOpen,
                      activeColor: Colors.greenAccent,
                      onChanged: (_) async {
                        // Logic simplified: No longer requesting lecturer location when opening session.
                        await codeController.toggleSessionStatus(session);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text('Check-In List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Icon(Icons.sync, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text('Live Update', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text('Waiting for students...', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: Colors.tealAccent.withValues(alpha: 0.1),
                                child: Text('${index + 1}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              title: Text(record.studentId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: Text('At ${timeFormat.format(record.checkInTime)}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                              trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniToggle({required String label, required bool value, required ValueChanged<bool> onChanged, Color? activeColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 2),
                Text(value ? 'ON' : 'OFF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: value ? (activeColor ?? Colors.tealAccent) : Colors.redAccent)),
              ],
            ),
            const Spacer(),
            Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: activeColor ?? Colors.tealAccent,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
