import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/utils/constants.dart';

class RegisterController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController;

  RegisterController(this.authController);

  Future<bool> register({
    required String userId,
    required String password,
    required String username,
    required String role,
    String programCode = '',
    String programName = '',
    String faculty = '',
    int currentSem = 0,
    String department = 'Pusat ADAB',
    String status = 'Active',
  }) async {
    authController.isLoading = true;
    authController.errorMessage = null;

    try {
      final cleanUserId = userId.trim();
      final cleanName = username.trim();
      final cleanRole = UserModel.normalizeRole(role);
      final email = authController.idToEmail(cleanUserId);

      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        authController.errorMessage = 'Registration failed. Please try again.';
        authController.isLoading = false;
        return false;
      }

      final newUser = UserModel(
        userId: cleanUserId,
        username: cleanName,
        role: cleanRole,
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid)
          .set({
        ...newUser.toMap(),
        'uid': firebaseUser.uid,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Extra document for co-curriculum module.
      if (cleanRole == UserModel.roleStudent) {
        await _firestore.collection('Student').doc(cleanUserId).set({
          'student_id': cleanUserId,
          'full_name': cleanName,
          'student_email': email,
          'program_code': programCode.trim(),
          'program_name': programName.trim(),
          'faculty': faculty.trim(),
          'current_sem': currentSem,
          'co_curriculum_credit': 0,
          'date_created': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (cleanRole == UserModel.rolePusatAdab) {
        await _firestore.collection('PusatAdab').doc(cleanUserId).set({
          'staff_id': cleanUserId,
          'staff_name': cleanName,
          'staff_email': email,
          'department': department.trim().isEmpty ? 'Pusat ADAB' : department.trim(),
          'role': 'Pusat ADAB',
          'status': status.trim().isEmpty ? 'Active' : status.trim(),
          'date_created': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await authController.fetchUserDetails(firebaseUser.uid);
      authController.isLoading = false;
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        authController.errorMessage = 'This User ID is registered with a different password.';
      } else if (e.code == 'weak-password') {
        authController.errorMessage = 'Password must be at least 6 characters.';
      } else {
        authController.errorMessage = e.message ?? 'Registration failed.';
      }
    } catch (e) {
      authController.errorMessage = 'Error: $e';
    }

    authController.isLoading = false;
    return false;
  }
}
