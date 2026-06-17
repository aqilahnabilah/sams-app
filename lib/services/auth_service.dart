import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // OOP METHOD: This getter exposes Firebase authentication state to the app.
  Stream<User?> get userStream => _auth.authStateChanges();

  // OOP METHOD: This getter returns the currently signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  // OOP METHOD: This method standardizes every role value before routing.
  // This prevents invalid role issues when Firestore stores values such as
  // "Pusat ADAB", "pusat adab", "adab_staff" or "staff_adab".
  String normalizeRole(String? role) {
    final value = (role ?? '').trim().toLowerCase().replaceAll('-', '_');

    if (value == 'student') return 'student';
    if (value == 'lecturer') return 'lecturer';
    if (value == 'faculty_registrar' ||
        value == 'faculty registrar' ||
        value == 'registrar') {
      return 'faculty_registrar';
    }
    if (value == 'pusat_adab' ||
        value == 'pusat adab' ||
        value == 'adab' ||
        value == 'adab_staff' ||
        value == 'staff_adab' ||
        value == 'pusatadab') {
      return 'pusat_adab';
    }

    return value;
  }

  // OOP METHOD: This method signs in an existing user with Firebase Auth.
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // OOP METHOD: This method registers a user, stores the account role,
  // and creates the related Student or PusatAdab document based on ERD fields.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String programCode = '',
    String programName = '',
    String faculty = '',
    int currentSem = 0,
    String department = 'Pusat ADAB',
    String status = 'Active',
  }) async {
    try {
      final normalizedRole = normalizeRole(role);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Main login account document. Login routing depends on this collection.
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': normalizedRole,
          'role_label': roleLabel(normalizedRole),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Student table according to Module 2 ERD / data dictionary.
        if (normalizedRole == 'student') {
          await _firestore.collection('Student').doc(email).set({
            'student_id': email,
            'full_name': name,
            'student_email': email,
            'program_code': programCode,
            'program_name': programName,
            'faculty': faculty,
            'current_sem': currentSem,
            'co_curriculum_credit': 0,
            'date_created': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // PusatAdab table according to Module 2 ERD / data dictionary.
        if (normalizedRole == 'pusat_adab') {
          await _firestore.collection('PusatAdab').doc(email).set({
            'staff_id': email,
            'staff_name': name,
            'staff_email': email,
            'department': department.isEmpty ? 'Pusat ADAB' : department,
            'role': 'Pusat ADAB',
            'status': status.isEmpty ? 'Active' : status,
            'date_created': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // OOP METHOD: This method returns the readable label for every role.
  String roleLabel(String role) {
    switch (normalizeRole(role)) {
      case 'student':
        return 'Student';
      case 'lecturer':
        return 'Lecturer';
      case 'faculty_registrar':
        return 'Faculty Registrar';
      case 'pusat_adab':
        return 'Pusat ADAB';
      default:
        return role;
    }
  }

  // OOP METHOD: This method retrieves and normalizes the user role from Firestore.
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return normalizeRole(data['role'] as String?);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // OOP METHOD: This method retrieves the display name stored in Firestore.
  Future<String> getUserName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['name'] ?? '').toString();
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  // OOP METHOD: This method signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
