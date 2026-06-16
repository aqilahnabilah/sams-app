// ignore_for_file: file_names, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/course_service.dart';
import 'AddSubject.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final CourseService _courseService = CourseService();

  void _navigateToAddSubjectPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddSubjectPage(),
      ),
    );
  }

  void _navigateToEditSubjectPage(BuildContext context, String docId, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddSubjectPage(
          subjectId: docId,
          subjectData: data,
        ),
      ),
    );
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
              Color(0xFF1F1C2C),
              Color(0xFF928DAB),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Manage Courses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subtitle
                Text(
                  'Active Subjects & Sections',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Real-time Subjects Stream
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _courseService.getSubjectsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
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
                                Icons.menu_book,
                                size: 80,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subjects found',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button below to add a subject.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
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
                          final data = doc.data() as Map<String, dynamic>;
                          final String docId = doc.id;
                          
                          final String code = data['code'] ?? '';
                          final String name = data['name'] ?? '';
                          final String lecturer = data['lecturer'] ?? '';
                          
                          final List<dynamic> lectures = data['lectures'] ?? [];
                          final List<dynamic> labs = data['labs'] ?? [];
                          
                          final String fallbackSection = data['section'] ?? '';
                          final int fallbackCapacity = data['capacity'] ?? 0;
                          final int fallbackRegistered = data['registeredCount'] ?? 0;

                          return _buildSubjectCard(
                                docId: docId,
                                code: code,
                                name: name,
                                lecturer: lecturer,
                                lectures: lectures,
                                labs: labs,
                                fallbackSection: fallbackSection,
                                fallbackCapacity: fallbackCapacity,
                                fallbackRegistered: fallbackRegistered,
                                subjectData: data,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => _navigateToAddSubjectPage(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  String _format24hTime(String time24h) {
    try {
      final parts = time24h.split(':');
      if (parts.length != 2) return time24h;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $ampm';
    } catch (e) {
      return time24h;
    }
  }

  String _formatDayShort(String day) {
    if (day.length > 3) {
      return day.substring(0, 3);
    }
    return day;
  }

  Widget _buildSubjectCard({
    required String docId,
    required String code,
    required String name,
    required String lecturer,
    required List<dynamic> lectures,
    required List<dynamic> labs,
    required String fallbackSection,
    required int fallbackCapacity,
    required int fallbackRegistered,
    required Map<String, dynamic> subjectData,
  }) {
    // Compute total seats capacity and registered count across sections
    int totalCapacity = 0;
    int totalRegistered = 0;

    if (lectures.isNotEmpty) {
      for (var lec in lectures) {
        totalCapacity += (lec['capacity'] as num).toInt();
        totalRegistered += (lec['registeredCount'] as num).toInt();
      }
    } else {
      totalCapacity = fallbackCapacity;
      totalRegistered = fallbackRegistered;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header: Subject Code Badge & Delete Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade500.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.indigo.shade400.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.tealAccent),
                          onPressed: () => _navigateToEditSubjectPage(context, docId, subjectData),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                          onPressed: () => _confirmDelete(docId, code),
                        ),
                      ],
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
                const SizedBox(height: 16),

                // Divider line
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),

                // Details Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.person_outline, lecturer),
                          const SizedBox(height: 8),
                          
                          // Display grouped lectures & labs
                          if (lectures.isNotEmpty) ...[
                            ...lectures.map<Widget>((lec) {
                              final lecName = lec['name'] ?? '';
                              final lecDay = lec['day'] ?? '';
                              final lecStart = lec['startTime'] ?? '';
                              final lecEnd = lec['endTime'] ?? '';
                              final lecCap = lec['capacity'] ?? 0;
                              final lecReg = lec['registeredCount'] ?? 0;

                              // Filter labs that belong to this lecture section
                              final assocLabs = labs.where((lab) => lab['parentLecture'] == lecName).toList();

                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Lecture header line
                                    Row(
                                      children: [
                                        Icon(Icons.menu_book_outlined, size: 16, color: Colors.tealAccent.withOpacity(0.8)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Lec $lecName: ${_formatDayShort(lecDay)} ${_format24hTime(lecStart)}-${_format24hTime(lecEnd)} ($lecReg/$lecCap)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (assocLabs.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 24.0),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: assocLabs.map<Widget>((lab) {
                                            final labName = lab['name'] ?? '';
                                            final labCap = lab['capacity'] ?? 0;
                                            final labReg = lab['registeredCount'] ?? 0;
                                            final labDay = lab['day'] ?? '';
                                            final labStart = lab['startTime'] ?? '';
                                            final labEnd = lab['endTime'] ?? '';

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.04),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                              ),
                                              child: Text(
                                                '$labName ($labReg/$labCap) • ${_formatDayShort(labDay)} ${_format24hTime(labStart)}-${_format24hTime(labEnd)}',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            })
                          ] else ...[
                            _buildDetailRow(Icons.meeting_room_outlined, 'Section: $fallbackSection'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Aggregated Total Capacity Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$totalRegistered / $totalCapacity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Seats',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String docId, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1C2C),
        title: const Text(
          'Delete Subject?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove the subject $code?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await _courseService.deleteSubject(docId);
                messenger.showSnackBar(
                  SnackBar(content: Text('$code removed successfully.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete subject: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
