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
}
