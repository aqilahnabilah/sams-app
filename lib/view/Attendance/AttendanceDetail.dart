import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-315 — Single attendance record metadata detail.
class AttendanceDetailPage extends StatelessWidget {
  const AttendanceDetailPage({super.key, required this.record});

  final AttendanceRecordModel record;

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('EEEE, dd MMMM yyyy');
    final timeFormat = intl.DateFormat('HH:mm:ss');

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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Attendance Detail',
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
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            record.attendanceStatus == 'Present'
                                ? Icons.verified
                                : Icons.pending,
                            size: 64,
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            record.attendanceStatus.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _DetailTile(
                      icon: Icons.tag,
                      label: 'Attendance ID',
                      value: record.attendanceId,
                    ),
                    _DetailTile(
                      icon: Icons.class_,
                      label: 'Class Session',
                      value: record.classSessionId,
                    ),
                    _DetailTile(
                      icon: Icons.pin,
                      label: 'Code ID',
                      value: record.codeId,
                    ),
                    _DetailTile(
                      icon: Icons.person,
                      label: 'Student ID',
                      value: record.studentId,
                    ),
                    _DetailTile(
                      icon: Icons.place,
                      label: 'Location ID',
                      value: record.locationId,
                    ),
                    _DetailTile(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: dateFormat.format(record.checkInTime),
                    ),
                    _DetailTile(
                      icon: Icons.access_time,
                      label: 'Check-in Time',
                      value: timeFormat.format(record.checkInTime),
                    ),
                    _DetailTile(
                      icon: Icons.my_location,
                      label: 'Coordinates',
                      value:
                          '${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}',
                    ),
                    if (record.remarks.isNotEmpty)
                      _DetailTile(
                        icon: Icons.notes,
                        label: 'Remarks',
                        value: record.remarks,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.tealAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
