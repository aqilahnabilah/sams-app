import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/SubjectRegistrationModel.dart';

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
    required int creditHour,
    required String examDate,
    required String examTime,
    required List<Map<String, dynamic>> lectures,
    required List<Map<String, dynamic>> labs,
  }) async {
    try {
      await _firestore.collection('subjects').add({
        'code': code.toUpperCase(),
        'name': name,
        'lecturer': lecturer,
        'creditHour': creditHour,
        'examDate': examDate,
        'examTime': examTime,
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
    required int creditHour,
    required String examDate,
    required String examTime,
    required List<Map<String, dynamic>> lectures,
    required List<Map<String, dynamic>> labs,
  }) async {
    try {
      await _firestore.collection('subjects').doc(documentId).update({
        'code': code.toUpperCase(),
        'name': name,
        'lecturer': lecturer,
        'creditHour': creditHour,
        'examDate': examDate,
        'examTime': examTime,
        'lectures': lectures,
        'labs': labs,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Submit subject registration for approval and decrement capacity immediately
  Future<void> submitRegistration(SubjectRegistrationModel registration) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final subjectDocRef = _firestore.collection('subjects').doc(registration.subjectId);
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
          if (lectures[i]['name'] == registration.sectionName) {
            sectionFound = true;
            final currentReg = (lectures[i]['registeredCount'] as num?)?.toInt() ?? 0;
            final capacity = (lectures[i]['capacity'] as num?)?.toInt() ?? 999;
            if (currentReg >= capacity) {
              throw Exception('This section (${registration.sectionName}) is already full.');
            }
            lectures[i]['registeredCount'] = currentReg + 1;
          }
        }

        if (!sectionFound) {
          throw Exception('Selected section not found in the subject.');
        }

        // Increment registeredCount in matching lab
        if (registration.labSectionName.isNotEmpty) {
          bool labFound = false;
          for (var i = 0; i < labs.length; i++) {
            if (labs[i]['name'] == registration.labSectionName && labs[i]['parentLecture'] == registration.sectionName) {
              labFound = true;
              final currentReg = (labs[i]['registeredCount'] as num?)?.toInt() ?? 0;
              final capacity = (labs[i]['capacity'] as num?)?.toInt() ?? 999;
              if (currentReg >= capacity) {
                throw Exception('This lab section (${registration.labSectionName}) is already full.');
              }
              labs[i]['registeredCount'] = currentReg + 1;
              break;
            }
          }
          if (!labFound) {
            throw Exception('Selected lab section not found in the subject.');
          }
        }

        // Add the registration document
        final regCollection = _firestore.collection('registrations');
        final newRegRef = regCollection.doc();
        transaction.set(newRegRef, registration.toMap());

        // Update the subject document
        transaction.update(subjectDocRef, {
          'lectures': lectures,
          'labs': labs,
        });
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

  // Stream of registrations for a specific student
  Stream<QuerySnapshot> getStudentRegistrationsStream(String studentEmail) {
    return _firestore
        .collection('registrations')
        .where('studentEmail', isEqualTo: studentEmail)
        .snapshots();
  }

  // Transaction-safe approval that updates status to approved (capacity was decremented on submit)
  Future<void> approveRegistration({
    required String registrationId,
    required String subjectId,
    required String sectionName,
    String? labSectionName,
  }) async {
    try {
      await _firestore.collection('registrations').doc(registrationId).update({
        'status': 'approved',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reject a student registration and release the reserved seat (decrement registeredCount)
  Future<void> rejectRegistration(String registrationId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final regDocRef = _firestore.collection('registrations').doc(registrationId);
        final regSnapshot = await transaction.get(regDocRef);
        if (!regSnapshot.exists) {
          throw Exception('Registration document does not exist.');
        }

        final regData = regSnapshot.data() as Map<String, dynamic>;
        final String status = regData['status'] ?? 'pending';

        // Only release the seat if the registration was pending or approved (not already rejected)
        if (status == 'rejected') {
          return;
        }

        final String subjectId = regData['subjectId'] ?? '';
        final String sectionName = regData['sectionName'] ?? '';
        final String labSectionName = regData['labSectionName'] ?? '';

        final subjectDocRef = _firestore.collection('subjects').doc(subjectId);
        final subjectSnapshot = await transaction.get(subjectDocRef);

        if (subjectSnapshot.exists) {
          final subjectData = subjectSnapshot.data() as Map<String, dynamic>;
          final List<dynamic> lectures = List.from(subjectData['lectures'] ?? []);
          final List<dynamic> labs = List.from(subjectData['labs'] ?? []);

          // Decrement registeredCount in lectures
          for (var i = 0; i < lectures.length; i++) {
            if (lectures[i]['name'] == sectionName) {
              final currentReg = (lectures[i]['registeredCount'] as num?)?.toInt() ?? 0;
              lectures[i]['registeredCount'] = currentReg > 0 ? currentReg - 1 : 0;
            }
          }

          // Decrement registeredCount in matching lab
          if (labSectionName.isNotEmpty) {
            for (var i = 0; i < labs.length; i++) {
              if (labs[i]['name'] == labSectionName && labs[i]['parentLecture'] == sectionName) {
                final currentReg = (labs[i]['registeredCount'] as num?)?.toInt() ?? 0;
                labs[i]['registeredCount'] = currentReg > 0 ? currentReg - 1 : 0;
                break;
              }
            }
          }

          // Update the subject document
          transaction.update(subjectDocRef, {
            'lectures': lectures,
            'labs': labs,
          });
        }

        // Update the registration status to rejected
        transaction.update(regDocRef, {'status': 'rejected'});
      });
    } catch (e) {
      rethrow;
    }
  }

  // Drop a subject registration: decrement registered counts (releasing the seat) and delete registration doc
  Future<void> dropRegistration(String registrationId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final regDocRef = _firestore.collection('registrations').doc(registrationId);
        final regSnapshot = await transaction.get(regDocRef);
        if (!regSnapshot.exists) {
          throw Exception('Registration document does not exist.');
        }

        final regData = regSnapshot.data() as Map<String, dynamic>;
        final String status = regData['status'] ?? 'pending';

        // Only release the seat if the registration was pending or approved (not already rejected/dropped)
        if (status != 'rejected') {
          final String subjectId = regData['subjectId'] ?? '';
          final String sectionName = regData['sectionName'] ?? '';
          final String labSectionName = regData['labSectionName'] ?? '';

          final subjectDocRef = _firestore.collection('subjects').doc(subjectId);
          final subjectSnapshot = await transaction.get(subjectDocRef);

          if (subjectSnapshot.exists) {
            final subjectData = subjectSnapshot.data() as Map<String, dynamic>;
            final List<dynamic> lectures = List.from(subjectData['lectures'] ?? []);
            final List<dynamic> labs = List.from(subjectData['labs'] ?? []);

            // Decrement registeredCount in lectures
            for (var i = 0; i < lectures.length; i++) {
              if (lectures[i]['name'] == sectionName) {
                final currentReg = (lectures[i]['registeredCount'] as num?)?.toInt() ?? 0;
                lectures[i]['registeredCount'] = currentReg > 0 ? currentReg - 1 : 0;
              }
            }

            // Decrement registeredCount in matching lab
            if (labSectionName.isNotEmpty) {
              for (var i = 0; i < labs.length; i++) {
                if (labs[i]['name'] == labSectionName && labs[i]['parentLecture'] == sectionName) {
                  final currentReg = (labs[i]['registeredCount'] as num?)?.toInt() ?? 0;
                  labs[i]['registeredCount'] = currentReg > 0 ? currentReg - 1 : 0;
                  break;
                }
              }
            }

            // Update the subject document
            transaction.update(subjectDocRef, {
              'lectures': lectures,
              'labs': labs,
            });
          }
        }

        // Delete the registration document
        transaction.delete(regDocRef);
      });
    } catch (e) {
      rethrow;
    }
  }

  // Set notifiedAdvisor flag to true on the registration document
  Future<void> notifyAdvisor(String registrationId) async {
    try {
      await _firestore.collection('registrations').doc(registrationId).update({
        'notifiedAdvisor': true,
      });
    } catch (e) {
      rethrow;
    }
  }
}

