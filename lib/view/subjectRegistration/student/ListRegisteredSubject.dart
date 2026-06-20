// File: ListRegisteredSubject.dart
// Path: lib/view/subjectRegistration/student/ListRegisteredSubject.dart
// Purpose: Screen for students to view their own active and pending subject registrations, as well as drop subjects.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../provider/subjectregistration/SubjectRegistrationController.dart';
import '../../../domain/subjectregistration/SubjectRegistrationModel.dart';

/// A screen that lists all subject registrations for a specific student.
class ListRegisteredSubjectsPage extends StatefulWidget {
  final String studentEmail;
  final String studentName;

  const ListRegisteredSubjectsPage({
    super.key,
    required this.studentEmail,
    required this.studentName,
  });

  @override
  State<ListRegisteredSubjectsPage> createState() => _ListRegisteredSubjectsPageState();
}

/// State for [ListRegisteredSubjectsPage] handles retrieving list of registrations and dropping subjects.
class _ListRegisteredSubjectsPageState extends State<ListRegisteredSubjectsPage> {
  final SubjectRegistrationController _courseService = SubjectRegistrationController();
  final Map<String, bool> _processingItems = {};

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime24hTo12h(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _handleDrop(String regId, String subjectCode) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1C2C),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade400),
            const SizedBox(width: 8),
            const Text('Drop Subject', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to drop $subjectCode? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Drop'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _processingItems[regId] = true;
    });

    try {
      await _courseService.dropRegistration(regId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dropped $subjectCode successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to drop subject: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingItems[regId] = false;
        });
      }
    }
  }

  Future<void> _handleNotify(String regId, String subjectCode) async {
    setState(() {
      _processingItems[regId] = true;
    });

    try {
      await _courseService.notifyAdvisor(regId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent to advisor for $subjectCode.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to notify advisor: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingItems[regId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Registered Subjects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Real-time Stream listing for Registered Subjects
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _courseService.getStudentRegistrationsStream(widget.studentEmail),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.tealAccent),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 80,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You haven\'t registered for any subjects yet.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort documents in-memory by createdAt descending
                      final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                      docs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['createdAt'] as Timestamp?;
                        final bTime = bData['createdAt'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime); // descending
                      });

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final regData = doc.data() as Map<String, dynamic>;
                          final String regId = doc.id;
                          final String code = regData['subjectCode'] ?? '';
                          final String name = regData['subjectName'] ?? '';
                          final String sectionName = regData['sectionName'] ?? '';
                          final String labSectionName = regData['labSectionName'] ?? '';
                          final String status = regData['status'] ?? 'pending';
                          final bool notified = regData['notifiedAdvisor'] ?? false;
                          final List<dynamic> lectures = regData['lectures'] ?? [];
                          final List<dynamic> labs = regData['labs'] ?? [];
                          final String examDate = regData['examDate'] ?? '';
                          final String examTime = regData['examTime'] ?? '';
                          final int creditHour = regData['creditHour'] ?? 0;

                          final bool isProcessing = _processingItems[regId] ?? false;

                          Color statusColor;
                          Color statusBgColor;
                          IconData statusIcon;

                          switch (status.toLowerCase()) {
                            case 'approved':
                              statusColor = Colors.greenAccent;
                              statusBgColor = Colors.green.shade500.withOpacity(0.15);
                              statusIcon = Icons.check_circle_outline;
                              break;
                            case 'rejected':
                              statusColor = Colors.redAccent;
                              statusBgColor = Colors.red.shade500.withOpacity(0.15);
                              statusIcon = Icons.error_outline;
                              break;
                            default: // pending
                              statusColor = Colors.amberAccent;
                              statusBgColor = Colors.amber.shade500.withOpacity(0.15);
                              statusIcon = Icons.hourglass_empty;
                          }

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Code badge and status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            code,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.12),
                                            ),
                                          ),
                                          child: Text(
                                            '$creditHour Credits',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, color: statusColor, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            status[0].toUpperCase() + status.substring(1),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Subject Name
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (examDate.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.5)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Exam: ${_formatDateString(examDate)}' + (examTime.isNotEmpty ? ' @ ${_formatTime24hTo12h(examTime)}' : ''),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                const SizedBox(height: 12),
                                // Class section & schedules
                                Row(
                                  children: [
                                    Text(
                                      'Section: $sectionName',
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (labSectionName.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Lab Section: $labSectionName',
                                        style: const TextStyle(
                                          color: Colors.tealAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (notified) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.mark_email_read_outlined, color: Colors.greenAccent, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Advisor notified',
                                        style: TextStyle(
                                          color: Colors.greenAccent.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Action Buttons
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Notify Advisor Button (Only if pending & not yet notified)
                                    if (status.toLowerCase() == 'pending' && !notified)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.amberAccent,
                                        ),
                                        onPressed: isProcessing
                                            ? null
                                            : () => _handleNotify(regId, code),
                                        icon: const Icon(Icons.email_outlined, size: 16),
                                        label: const Text(
                                          'Notify Advisor',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (status.toLowerCase() == 'pending' && !notified)
                                      const SizedBox(width: 12),
                                    // Drop Subject Button (Only if pending or approved)
                                    if (status.toLowerCase() != 'rejected')
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: isProcessing
                                            ? null
                                            : () => _handleDrop(regId, code),
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        label: const Text(
                                          'Drop Subject',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
