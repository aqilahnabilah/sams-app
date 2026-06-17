import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-310 — "Manage Attendance" UI with Dark Gradient Theme.
class LectureAttendancePage extends StatefulWidget {
  const LectureAttendancePage({super.key});

  @override
  State<LectureAttendancePage> createState() => _LectureAttendancePageState();
}

class _LectureAttendancePageState extends State<LectureAttendancePage> {
  ClassSessionModel? _selectedSession;
  bool _loading = true;
  List<ClassSessionModel> _historySessions = [];
  final Map<String, int> _sessionCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  Future<void> _initPage() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    final staffId = user.userId;

    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is ClassSessionModel) {
      _selectedSession = args;
    } else if (args is Map<String, dynamic>) {
      _selectedSession = ClassSessionModel(
        classSessionId: 'SESSION_${args['subjectCode']}',
        staffId: staffId,
        subjectCode: args['subjectCode'] ?? 'BCS3133',
        subjectName: args['subjectName'] ?? 'Software Engineering Practices',
        classSection: '01',
        classDate: '2024-05-20',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        sessionStatus: 'Closed',
      );
    }

    if (_selectedSession == null) {
      _selectedSession = ClassSessionModel(
        classSessionId: 'SESS001',
        staffId: staffId,
        subjectCode: 'BCS3133',
        subjectName: 'Software Engineering Practices',
        classSection: '01',
        classDate: '2024-05-20',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        sessionStatus: 'Closed',
      );
    }

    final controller = context.read<ClassCodeController>();
    await controller.fetchActiveCode(_selectedSession!.classSessionId);
    
    await _loadHistory();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null || _selectedSession == null) return;

    final att = context.read<AttendanceController>();
    final sessions = await att.fetchSubjectSessions(user.userId, _selectedSession!.subjectCode);
    
    // Filter to show only closed sessions in history
    final history = sessions.where((s) => s.sessionStatus == 'Closed').toList();
    
    for (var s in history) {
      final count = await att.getSessionAttendanceCount(s.classSessionId);
      _sessionCounts[s.classSessionId] = count;
    }

    if (mounted) {
      setState(() {
        _historySessions = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
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
                        'Manage Attendance',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.1),
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
                                        style: TextStyle(color: Colors.tealAccent.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                      
                      // QUICK TOGGLES
                      Row(
                        children: [
                          _miniToggle(
                            label: 'REQUIRE LOCATION',
                            value: codeController.requiresLocation,
                            onChanged: (_) => context.read<ClassCodeController>().toggleLocationRequirement(session.classSessionId),
                          ),
                          const SizedBox(width: 12),
                          _miniToggle(
                            label: 'SESSION STATUS',
                            value: isOpen,
                            activeColor: Colors.greenAccent,
                            onChanged: (_) async {
                              final loc = context.read<LocationVerification>();
                              final codeProv = context.read<ClassCodeController>();
                              double? lat, lng;
                              if (!isOpen) { 
                                await loc.checkGPSPermission();
                                await loc.verifyCurrentLocation();
                                lat = loc.currentLatitude;
                                lng = loc.currentLongitude;
                              }
                              if (mounted) {
                                await codeProv.toggleSessionStatus(session.classSessionId, lat: lat, lng: lng);
                                await _loadHistory();
                              }
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Attendance Code Section
                      Text(
                        'Attendance Code'.toUpperCase(),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
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
                                  backgroundColor: Colors.white.withOpacity(0.08),
                                  foregroundColor: Colors.tealAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Regenerate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Attendance History Section
                      if (_historySessions.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.history, color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historySessions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final hist = _historySessions[index];
                            final count = _sessionCounts[hist.classSessionId] ?? 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/lecturer/attendance-records',
                                    arguments: hist,
                                  );
                                },
                                title: Text(hist.classDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text('${hist.startTime} - ${hist.endTime}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
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
                              ),
                            );
                          },
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
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

  Widget _miniToggle({required String label, required bool value, required ValueChanged<bool> onChanged, Color? activeColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 2),
                  Text(value ? 'YES' : 'NO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value ? (activeColor ?? Colors.tealAccent) : Colors.redAccent)),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: (activeColor ?? Colors.tealAccent).withOpacity(0.3),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeDisplay(String? code) {
    if (code == null || code.isEmpty) {
      return Text('———', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.1), letterSpacing: 4));
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
