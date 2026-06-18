import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../domain/Authentication/UserModel.dart';
import '../../theme/sams_theme.dart';
import 'AttendanceDetail.dart';
import 'AttendanceRecordPage.dart';

/// SAMS-PACK-314 — Dual-role Attendance History Page.
/// Students see their check-ins; Lecturers see their completed sessions.
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecordModel> _studentRecords = [];
  List<ClassSessionModel> _lecturerSessions = [];
  final Map<String, int> _sessionCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final attController = context.read<AttendanceController>();

    try {
      if (user.role == UserModel.roleStudent) {
        // Load Student Check-in History
        _studentRecords = await attController.fetchStudentHistory(user.userId);
      } else if (user.role == UserModel.roleLecturer) {
        // Load Lecturer Session History
        final allSessions = await attController.fetchLecturerSessions(user.userId);
        debugPrint('SAMS_DEBUG: Found ${allSessions.length} sessions for lecturer ${user.userId}');
        _lecturerSessions = allSessions; // Controller already sorts newest-first
        
        for (var s in _lecturerSessions) {
          _sessionCounts[s.classSessionId] = await attController.getSessionAttendanceCount(s.classSessionId);
        }
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('SAMS_ERROR: _loadHistory: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLecturer = auth.currentUser?.role == UserModel.roleLecturer;

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
                        'Attendance History',
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: isLecturer ? _buildLecturerView() : _buildStudentView(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UI for Students: List of individual check-ins.
  Widget _buildStudentView() {
    final dateFormat = intl.DateFormat('dd MMM yyyy • HH:mm');
    
    if (_studentRecords.isEmpty) {
      return _buildEmptyState('No attendance records found');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _studentRecords.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _studentRecords[index];
        final isPresent = record.attendanceStatus == 'Present';
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPresent ? Colors.tealAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isPresent ? Icons.check_circle_outline : Icons.error_outline,
                color: isPresent ? Colors.tealAccent : Colors.redAccent,
              ),
            ),
            title: Text(
              _formatSubject(record.classSessionId),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(record.checkInTime), 
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AttendanceDetailPage(record: record),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// UI for Lecturers: List of created class sessions.
  Widget _buildLecturerView() {
    if (_lecturerSessions.isEmpty) {
      return _buildEmptyState('No historical sessions found');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _lecturerSessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _lecturerSessions[index];
        final count = _sessionCounts[session.classSessionId] ?? 0;
        final isOpen = session.isOpen();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOpen ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isOpen ? Icons.sensors : Icons.history,
                color: isOpen ? Colors.greenAccent : Colors.white70,
              ),
            ),
            title: Text(
              '${session.subjectCode} - Sec ${session.classSection}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${session.classDate} • ${session.startTime}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${session.sessionStatus}',
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.greenAccent : Colors.white38
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                    const Text('Present', style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2)),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/lecturer/attendance-records',
                arguments: session,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  String _formatSubject(String sessionId) {
    if (sessionId.startsWith('SESSION_')) {
      return sessionId.replaceFirst('SESSION_', '');
    }
    return sessionId;
  }
}
