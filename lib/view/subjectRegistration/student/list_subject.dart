// File: list_subject.dart
// Path: lib/view/subjectRegistration/student/list_subject.dart
// Purpose: Screen for students to view a list of all available subjects, search them, and select one to register.

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/course_service.dart';
import 'RegisterSubject.dart';
import 'ListRegisteredSubject.dart';

/// A screen showing available subjects that a student can register for.
class RegisterSubjectsPage extends StatefulWidget {
  final String studentEmail;
  final String studentName;

  const RegisterSubjectsPage({
    super.key,
    required this.studentEmail,
    required this.studentName,
  });

  @override
  State<RegisterSubjectsPage> createState() => _RegisterSubjectsPageState();
}

/// State for [RegisterSubjectsPage] managing search query and retrieving subjects.
class _RegisterSubjectsPageState extends State<RegisterSubjectsPage> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      'Subject Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by subject code or name...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white60),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Button/Card to redirect to ListRegisteredSubject
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListRegisteredSubjectsPage(
                              studentEmail: widget.studentEmail,
                              studentName: widget.studentName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade500.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.assignment_turned_in_outlined,
                                    color: Colors.tealAccent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Registered Subjects',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'View status, drop classes, or notify advisor.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.tealAccent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Available Subjects Section Title
                const Text(
                  'Available Subjects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Real-time Stream listing for Available Subjects
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _courseService.getSubjectsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.tealAccent),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading subjects: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState('No active subjects found.');
                      }

                      // Filter documents in memory by search query
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final code = (data['code'] ?? '').toString().toLowerCase();
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        return code.contains(_searchQuery) || name.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return _buildEmptyState('No matches found for "$_searchQuery".');
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final String docId = doc.id;
                          final String code = data['code'] ?? '';
                          final String name = data['name'] ?? '';
                          final List<dynamic> lectures = data['lectures'] ?? [];
                          final List<dynamic> labs = data['labs'] ?? [];
                          
                          final int fallbackCapacity = data['capacity'] ?? 0;
                          final int fallbackRegistered = data['registeredCount'] ?? 0;
                          final int creditHour = data['creditHour'] ?? 0;

                          final String examDate = data['examDate'] ?? '';
                          final String examTime = data['examTime'] ?? '';

                          return _buildSubjectCard(
                            docId: docId,
                            code: code,
                            name: name,
                            creditHour: creditHour,
                            examDate: examDate,
                            examTime: examTime,
                            lectures: lectures,
                            labs: labs,
                            fallbackCapacity: fallbackCapacity,
                            fallbackRegistered: fallbackRegistered,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 60,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard({
    required String docId,
    required String code,
    required String name,
    required int creditHour,
    required String examDate,
    required String examTime,
    required List<dynamic> lectures,
    required List<dynamic> labs,
    required int fallbackCapacity,
    required int fallbackRegistered,
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

    final int availableSeats = totalCapacity - totalRegistered;
    final bool isFull = availableSeats <= 0;

    return Opacity(
      opacity: isFull ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: isFull
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RegisterSubjectPage(
                          studentEmail: widget.studentEmail,
                          studentName: widget.studentName,
                          subjectId: docId,
                          subjectCode: code,
                          subjectName: name,
                          creditHour: creditHour,
                          examDate: examDate,
                          examTime: examTime,
                          lectures: lectures,
                          labs: labs,
                        ),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Code Badge and Subject Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Code & Credit Hour Badge Row
                        Row(
                          children: [
                            // Code Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade500.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.teal.shade400.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Credit Hour Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column: Status Badge and Quota Left
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Badge (Available/Full)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: availableSeats > 0
                              ? Colors.green.shade500.withOpacity(0.15)
                              : Colors.red.shade500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: availableSeats > 0
                                ? Colors.greenAccent.withOpacity(0.4)
                                : Colors.redAccent.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          availableSeats > 0 ? 'Available' : 'Full',
                          style: TextStyle(
                            color: availableSeats > 0 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quota Left
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Quota Left',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$availableSeats',
                            style: TextStyle(
                              color: availableSeats > 0 ? Colors.tealAccent : Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
