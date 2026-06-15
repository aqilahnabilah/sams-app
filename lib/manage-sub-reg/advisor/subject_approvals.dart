import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/course_service.dart';

class SubjectApprovalsPage extends StatefulWidget {
  const SubjectApprovalsPage({super.key});

  @override
  State<SubjectApprovalsPage> createState() => _SubjectApprovalsPageState();
}

class _SubjectApprovalsPageState extends State<SubjectApprovalsPage> {
  final CourseService _courseService = CourseService();
  final Map<String, bool> _processingItems = {};

  Future<void> _handleApprove(
    String regId,
    String subjectId,
    String sectionName,
    String labSectionName,
    String studentName,
    String subjectCode,
  ) async {
    setState(() {
      _processingItems[regId] = true;
    });

    try {
      await _courseService.approveRegistration(
        registrationId: regId,
        subjectId: subjectId,
        sectionName: sectionName,
        labSectionName: labSectionName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved $studentName for $subjectCode section $sectionName.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to approve: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Future<void> _handleReject(String regId, String studentName, String subjectCode) async {
    setState(() {
      _processingItems[regId] = true;
    });

    try {
      await _courseService.rejectRegistration(regId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejected registration request from $studentName.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to reject: $e'),
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
              Color(0xFF1D2671),
              Color(0xFFC33764),
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
                      'Registration Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pending requests builder
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _courseService.getPendingRegistrationsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.amberAccent),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading requests: ${snapshot.error}',
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
                                Icons.done_all,
                                size: 80,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pending approvals.',
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

                      final docs = snapshot.data!.docs;

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final regId = doc.id;
                          final data = doc.data() as Map<String, dynamic>;

                          final String studentName = data['studentName'] ?? '';
                          final String studentEmail = data['studentEmail'] ?? '';
                          final String subjectId = data['subjectId'] ?? '';
                          final String subjectCode = data['subjectCode'] ?? '';
                          final String subjectName = data['subjectName'] ?? '';
                          final String sectionName = data['sectionName'] ?? '';
                          final String labSectionName = data['labSectionName'] ?? '';
                          final List<dynamic> lectures = data['lectures'] ?? [];
                          final List<dynamic> labs = data['labs'] ?? [];

                          final bool isProcessing = _processingItems[regId] ?? false;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Student header row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          studentEmail,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.amber.shade600.withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'PENDING',
                                        style: TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                const SizedBox(height: 16),

                                // Subject code/name and section details
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        subjectCode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subjectName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Selected Section: $sectionName' + (labSectionName.isNotEmpty ? ' | Lab: $labSectionName' : ''),
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (lectures.isNotEmpty) ...[
                                  Text(
                                    'Lecture: ${lectures[0]['day']} • ${lectures[0]['startTime']}-${lectures[0]['endTime']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (labs.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lab: ${labs[0]['day']} • ${labs[0]['startTime']}-${labs[0]['endTime']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Action Buttons Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Reject Button
                                    TextButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _handleReject(regId, studentName, subjectCode),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text(
                                        'Reject Request',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Approve Button
                                    ElevatedButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _handleApprove(
                                                regId,
                                                subjectId,
                                                sectionName,
                                                labSectionName,
                                                studentName,
                                                subjectCode,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      ),
                                      child: isProcessing
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Approve',
                                              style: TextStyle(fontWeight: FontWeight.bold),
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
