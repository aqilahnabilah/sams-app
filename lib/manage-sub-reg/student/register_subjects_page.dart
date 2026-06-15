// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/course_service.dart';

class RegisterSubjectsPage extends StatefulWidget {
  const RegisterSubjectsPage({super.key});

  @override
  State<RegisterSubjectsPage> createState() => _RegisterSubjectsPageState();
}

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
                      'Available Subjects',
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
                const SizedBox(height: 20),

                // Real-time Stream listing
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
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final String code = data['code'] ?? '';
                          final String name = data['name'] ?? '';
                          final List<dynamic> lectures = data['lectures'] ?? [];
                          
                          final int fallbackCapacity = data['capacity'] ?? 0;
                          final int fallbackRegistered = data['registeredCount'] ?? 0;

                          return _buildSubjectCard(
                            code: code,
                            name: name,
                            lectures: lectures,
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
            size: 80,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            message,
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

  Widget _buildSubjectCard({
    required String code,
    required String name,
    required List<dynamic> lectures,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
      ),
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
                  const SizedBox(height: 12),
                  // Subject Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
    );
  }
}
