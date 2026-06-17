import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../theme/sams_theme.dart';
import 'AttendanceDetail.dart';

/// SAMS-PACK-314 — Chronological attendance history cards with Dark Gradient Theme.
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final studentId = user.userId;

    try {
      final records = await context
          .read<AttendanceController>()
          .fetchStudentHistory(studentId);

      if (mounted) {
        setState(() {
          _records = records;
        });
      }
    } catch (e) {
      debugPrint('_loadHistory error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('dd MMM yyyy • HH:mm');

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
                        child: _records.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 100),
                                  Center(
                                    child: Text(
                                      'No attendance records found',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                itemCount: _records.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final record = _records[index];
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
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSubject(String sessionId) {
    if (sessionId.startsWith('SESSION_')) {
      return sessionId.replaceFirst('SESSION_', '');
    }
    return sessionId;
  }
}
