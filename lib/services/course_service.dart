import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all subjects, ordered by creation time descending
  Stream<QuerySnapshot> getSubjectsStream() {
    return _firestore
        .collection('subjects')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add a new subject
  Future<void> addSubject({
    required String code,
    required String name,
    required String lecturer,
    required List<Map<String, dynamic>> lectures,
    required List<Map<String, dynamic>> labs,
  }) async {
    try {
      await _firestore.collection('subjects').add({
        'code': code.toUpperCase(),
        'name': name,
        'lecturer': lecturer,
        'lectures': lectures,
        'labs': labs,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete a subject (useful helper)
  Future<void> deleteSubject(String documentId) async {
    try {
      await _firestore.collection('subjects').doc(documentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing subject
  Future<void> updateSubject({
    required String documentId,
    required String code,
    required String name,
    required String lecturer,
    required List<Map<String, dynamic>> lectures,
    required List<Map<String, dynamic>> labs,
  }) async {
    try {
      await _firestore.collection('subjects').doc(documentId).update({
        'code': code.toUpperCase(),
        'name': name,
        'lecturer': lecturer,
        'lectures': lectures,
        'labs': labs,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Submit subject registration for approval
  Future<void> submitRegistration({
    required String studentEmail,
    required String studentName,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
    required String sectionName,
    String? labSectionName,
    required List<dynamic> lectures,
    required List<dynamic> labs,
  }) async {
    try {
      await _firestore.collection('registrations').add({
        'studentEmail': studentEmail,
        'studentName': studentName,
        'subjectId': subjectId,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'sectionName': sectionName,
        'labSectionName': labSectionName ?? '',
        'lectures': lectures,
        'labs': labs,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Stream of pending registrations for academic advisors
  Stream<QuerySnapshot> getPendingRegistrationsStream() {
    return _firestore
        .collection('registrations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Transaction-safe approval that increments registeredCount for lectures/labs
  Future<void> approveRegistration({
    required String registrationId,
    required String subjectId,
    required String sectionName,
    String? labSectionName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final regDocRef = _firestore.collection('registrations').doc(registrationId);
        final subjectDocRef = _firestore.collection('subjects').doc(subjectId);

        final subjectSnapshot = await transaction.get(subjectDocRef);
        if (!subjectSnapshot.exists) {
          throw Exception('Subject does not exist.');
        }

        final data = subjectSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> lectures = List.from(data['lectures'] ?? []);
        final List<dynamic> labs = List.from(data['labs'] ?? []);

        // Increment registeredCount in lectures
        bool sectionFound = false;
        for (var i = 0; i < lectures.length; i++) {
          if (lectures[i]['name'] == sectionName) {
            sectionFound = true;
            final currentReg = (lectures[i]['registeredCount'] as num?)?.toInt() ?? 0;
            final capacity = (lectures[i]['capacity'] as num?)?.toInt() ?? 999;
            if (currentReg >= capacity) {
              throw Exception('This section ($sectionName) is already full.');
            }
            lectures[i]['registeredCount'] = currentReg + 1;
          }
        }

        if (!sectionFound) {
          throw Exception('Selected section not found in the subject.');
        }

        // Increment registeredCount in matching lab
        if (labSectionName != null && labSectionName.isNotEmpty) {
          bool labFound = false;
          for (var i = 0; i < labs.length; i++) {
            if (labs[i]['name'] == labSectionName && labs[i]['parentLecture'] == sectionName) {
              labFound = true;
              final currentReg = (labs[i]['registeredCount'] as num?)?.toInt() ?? 0;
              final capacity = (labs[i]['capacity'] as num?)?.toInt() ?? 999;
              if (currentReg >= capacity) {
                throw Exception('This lab section ($labSectionName) is already full.');
              }
              labs[i]['registeredCount'] = currentReg + 1;
              break;
            }
          }
          if (!labFound) {
            throw Exception('Selected lab section not found in the subject.');
          }
        }

        // Apply updates
        transaction.update(regDocRef, {'status': 'approved'});
        transaction.update(subjectDocRef, {
          'lectures': lectures,
          'labs': labs,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reject a student registration
  Future<void> rejectRegistration(String registrationId) async {
    try {
      await _firestore
          .collection('registrations')
          .doc(registrationId)
          .update({'status': 'rejected'});
    } catch (e) {
      rethrow;
    }
  }
}

