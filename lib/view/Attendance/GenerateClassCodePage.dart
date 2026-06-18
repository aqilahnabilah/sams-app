import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Authentication/AuthController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-311 — Redesigned "Attendance" UI with Dark Gradient Theme.
/// If a session is Closed, the "Live" elements are cleared.
class GenerateClassCodePage extends StatefulWidget {
  const GenerateClassCodePage({super.key});

  @override
  State<GenerateClassCodePage> createState() => _GenerateClassCodePageState();
}

class _GenerateClassCodePageState extends State<GenerateClassCodePage> {
  ClassSessionModel? get _session {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ClassSessionModel) return args;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCode());
  }

  Future<void> _initCode() async {
    final session = _session;
    if (session == null) return;

    final controller = context.read<ClassCodeController>();
    final attController = context.read<AttendanceController>();

    await controller.fetchActiveCode(session.classSessionId);

    if (mounted) {
      attController.listenToSessionAttendance(session.classSessionId);
    }
  }

  @override
  void dispose() {
    context.read<AttendanceController>().stopListeningToSessionAttendance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codeController = context.watch<ClassCodeController>();
    final activeCode = codeController.activeCode;
    final isOpen = codeController.sessionStatus == 'Open';
    final session = _session;

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
                        'Attendance',
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
                      // Subject info card
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
                      
                      const SizedBox(height: 32),
                      
                      _toggleRow('Session Status (Open/Closed)', isOpen, (val) async {
                        final codeProv = context.read<ClassCodeController>();
                        await codeProv.toggleSessionStatus(session);
                      }),

                      if (isOpen) ...[
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 16),
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
                        _toggleRow('Require Location', codeController.requiresLocation, (val) {
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
