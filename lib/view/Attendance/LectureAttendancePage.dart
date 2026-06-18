import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../theme/sams_theme.dart';
import '../../utils/constants.dart';

/// SAMS-PACK-310 — "Attendance" UI with Dark Gradient Theme.
/// Resolves the discrepancy by using unique Session IDs for each class instance.
class LectureAttendancePage extends StatefulWidget {
  const LectureAttendancePage({super.key});

  @override
  State<LectureAttendancePage> createState() => _LectureAttendancePageState();
}

class _LectureAttendancePageState extends State<LectureAttendancePage> {
  ClassSessionModel? _selectedSession;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  /// Initializes the page by checking for an active session or creating a new unique one.
  Future<void> _initPage() async {
    final auth = context.read<AuthController>();
    final codeController = context.read<ClassCodeController>();

    final user = auth.currentUser;
    if (user == null) return;
    final staffId = user.userId;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final subjectCode = args['subjectCode'] ?? 'BCS3133';

    try {
      // 1. Check Firestore for any existing "Open" session for this subject by this lecturer.
      final activeQuery = await FirebaseFirestore.instance
          .collection(FirestoreCollections.classSessions)
          .where('staff_id', isEqualTo: staffId)
          .where('subject_code', isEqualTo: subjectCode)
          .where('session_status', isEqualTo: 'Open')
          .limit(1)
          .get();

      if (activeQuery.docs.isNotEmpty) {
        // Resume existing open session
        _selectedSession = ClassSessionModel.fromMap(activeQuery.docs.first.data());
        debugPrint('SAMS_DEBUG: Resuming existing open session: ${_selectedSession!.classSessionId}');
      } else {
        // No open session found. Prepare a NEW unique session ID for when they toggle to Open.
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _selectedSession = ClassSessionModel(
          classSessionId: 'SESS_${subjectCode}_$timestamp',
          staffId: staffId,
          subjectCode: subjectCode,
          subjectName: args['subjectName'] ?? 'Subject',
          classSection: args['classSection'] ?? '01',
          classDate: DateTime.now().toString().split(' ')[0],
          startTime: args['startTime'] ?? '10:00 AM',
          endTime: args['endTime'] ?? '12:00 PM',
          sessionStatus: 'Closed',
        );
        debugPrint('SAMS_DEBUG: Prepared new unique session ID: ${_selectedSession!.classSessionId}');
      }

      await codeController.fetchActiveCode(_selectedSession!.classSessionId);
      
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('SAMS_ERROR: _initPage: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: SamsColors.portalGradient)),
          child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
        )
      );
    }

    final codeController = context.watch<ClassCodeController>();
    final activeCode = codeController.activeCode;
    final isOpen = codeController.sessionStatus == 'Open';
    final session = _selectedSession!;

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
                        'Attendance',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // SUBJECT CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.book_outlined, color: Colors.tealAccent),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subject'.toUpperCase(),
                                        style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${session.subjectCode} ${session.subjectName}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _infoItem(Icons.calendar_today_outlined, 'Session', 'Lecture - Sec ${session.classSection}'),
                                const SizedBox(width: 16),
                                _infoItem(Icons.access_time, 'Time', session.startTime),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // SESSION STATUS TOGGLE
                      _toggleRow('Session Status (Open/Closed)', isOpen, (val) async {
                        final codeProv = context.read<ClassCodeController>();
                        if (mounted) {
                          await codeProv.toggleSessionStatus(session);
                        }
                      }),
                      
                      const SizedBox(height: 32),

                      if (isOpen) ...[
                        // Attendance Code Section
                        Text(
                          'Attendance Code'.toUpperCase(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          ),
                          child: Center(
                            child: _buildCodeDisplay(activeCode?.classCode),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Actions
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton.icon(
                            onPressed: () => context.read<ClassCodeController>().generateClassCode(session.classSessionId, session.staffId),
                            icon: const Icon(Icons.flash_on),
                            label: const Text('Generate Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/lecturer/attendance-records',
                                      arguments: session,
                                    );
                                  },
                                  icon: const Icon(Icons.people_outline),
                                  label: const Text('Live Records', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    foregroundColor: Colors.tealAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: activeCode == null ? null : () => context.read<ClassCodeController>().regenerateClassCode(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Regenerate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _toggleRowSmall('Require Location', codeController.requiresLocation, (val) {
                          context.read<ClassCodeController>().toggleLocationRequirement(session.classSessionId);
                        }),
                      ] else ...[
                        const SizedBox(height: 40),
                        Icon(Icons.lock_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'Session is currently closed.\nOpen the session to start recording attendance.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 40),
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

  Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Text(
            value ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              color: value ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRowSmall(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 2),
                Text(value ? 'YES' : 'NO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value ? Colors.tealAccent : Colors.redAccent)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: Colors.tealAccent.withValues(alpha: 0.3),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay(String? code) {
    if (code == null || code.isEmpty) {
      return Text('———', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.1), letterSpacing: 4));
    }
    final top = code.length >= 3 ? code.substring(0, 3) : code;
    final bottom = code.length > 3 ? code.substring(3) : '';
    return Column(
      children: [
        Text('${top.split('').join(' ')} -', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.tealAccent, height: 1.1)),
        if (bottom.isNotEmpty)
          Text(bottom.split('').join(' '), style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.tealAccent, height: 1.1)),
      ],
    );
  }
}
