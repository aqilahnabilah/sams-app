import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/course_service.dart';
import '../../../domain/subjectregistration/SubjectRegistrationModel.dart';
import '../../../theme/sams_theme.dart';

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
            colors: SamsColors.portalGradient,
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

                      final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                      docs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['createdAt'] as Timestamp?;
                        final bTime = bData['createdAt'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final reg = SubjectRegistrationModel.fromDocument(doc);
                          final bool isProcessing = _processingItems[reg.id] ?? false;

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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reg.studentName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            reg.studentEmail,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
                                        reg.subjectCode,
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
                                        reg.subjectName,
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
                                const SizedBox(height: 20),

                                // Action Buttons Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Reject Button
                                    TextButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _handleReject(reg.id, reg.studentName, reg.subjectCode),
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
                                                reg.id,
                                                reg.subjectId,
                                                reg.sectionName,
                                                reg.labSectionName,
                                                reg.studentName,
                                                reg.subjectCode,
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
