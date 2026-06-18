import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/co_curriculum/StudentModel.dart';
import '../../domain/co_curriculum/StudentCoCurriculumRecordModel.dart';
import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../domain/co_curriculum/CoCurriculumModuleModel.dart';

class CoCurriculumController extends ChangeNotifier {
  // Firebase Firestore instance used as backend database.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading and error states for view pages.
  bool isLoading = false;
  String error_message = '';

  // Entity objects used by the Manage Co-curriculum module.
  StudentModel? student;
  CoCurriculumClaimModel? claim;

  // List of student co-curriculum records retrieved from Firestore.
  List<StudentCoCurriculumRecordModel> records = [];

  // List of all claims used by Pusat ADAB.
  List<CoCurriculumClaimModel> claims = [];

  // Module information is stored in a map to easily get module details by module_id.
  Map<String, CoCurriculumModuleModel> modules = {};

  // Retrieves student information from the Student collection.
  Future<void> getStudentDetail(String student_id) async {
    try {
      final doc = await _firestore.collection('Student').doc(student_id).get();

      if (doc.exists) {
        student = StudentModel.fromFirestore(doc);
      }

      notifyListeners();
    } catch (e) {
      error_message = 'Failed to retrieve student information.';
      notifyListeners();
    }
  }

  // Retrieves student co-curriculum records based on student_id.
  // This method supports the student view record requirement.
  Future<void> getStudentRecords(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      await getStudentDetail(student_id);

      final snapshot = await _firestore
          .collection('StudentCoCurriculumRecord')
          .where('student_id', isEqualTo: student_id)
          .get();

      records = snapshot.docs
          .map((doc) => StudentCoCurriculumRecordModel.fromFirestore(doc))
          .toList();

      await getCoCurriculumModules();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve co-curriculum records.';
      notifyListeners();
    }
  }

  // Retrieves co-curriculum module details from Firestore.
  // This allows the view page to display module name, category and status.
  Future<void> getCoCurriculumModules() async {
    try {
      final snapshot = await _firestore.collection('CoCurriculumModule').get();

      modules = {
        for (var doc in snapshot.docs)
          doc.id: CoCurriculumModuleModel.fromFirestore(doc),
      };

      notifyListeners();
    } catch (e) {
      error_message = 'Failed to retrieve co-curriculum modules.';
      notifyListeners();
    }
  }

  // Counts the number of completed modules.
  // The student must complete at least 4 modules before claiming credit.
  int getCompletedModuleCount() {
    return records.where((record) => record.isCompleted()).length;
  }

  // Checks whether the student is eligible to submit a co-curriculum claim.
  Future<bool> checkEligibility(String student_id) async {
    await getStudentRecords(student_id);

    return getCompletedModuleCount() >= 4;
  }

  // Checks whether the student already submitted a claim.
  // This prevents duplicate claim submission.
  Future<bool> checkDuplicateClaim(String student_id) async {
    final snapshot = await _firestore
        .collection('CoCurriculumClaim')
        .where('student_id', isEqualTo: student_id)
        .where(
          'claim_status',
          whereIn: ['Pending Verification', 'Approved'],
        )
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Creates a new co-curriculum claim with Pending Verification status.
  // This method returns a message for the boundary/view page to display.
  Future<String> submitClaim(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final isEligible = await checkEligibility(student_id);

      if (isEligible == false) {
        isLoading = false;
        notifyListeners();
        return 'Student must complete 4 modules before claiming.';
      }

      final hasDuplicate = await checkDuplicateClaim(student_id);

      if (hasDuplicate == true) {
        isLoading = false;
        notifyListeners();
        return 'Co-curriculum credit has already been claimed.';
      }

      final claimRef = _firestore.collection('CoCurriculumClaim').doc();

      final newClaim = CoCurriculumClaimModel(
        claim_id: claimRef.id,
        student_id: student_id,
        completed_module_count: getCompletedModuleCount(),
        claim_status: 'Pending Verification',
        submission_date: DateTime.now(),
        credit_awarded: 2,
      );

      await claimRef.set(newClaim.toFirestore());

      isLoading = false;
      notifyListeners();

      return 'Claim submitted successfully.';
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to submit claim.';
      notifyListeners();

      return 'Failed to submit claim.';
    }
  }

  // Retrieves the latest claim status for a selected student.
  // This supports the ClaimStatusPage boundary class.
  Future<CoCurriculumClaimModel?> getClaimStatus(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final snapshot = await _firestore
          .collection('CoCurriculumClaim')
          .where('student_id', isEqualTo: student_id)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final studentClaims = snapshot.docs
            .map((doc) => CoCurriculumClaimModel.fromFirestore(doc))
            .toList();

        studentClaims.sort(
          (a, b) => b.submission_date.compareTo(a.submission_date),
        );

        claim = studentClaims.first;
      } else {
        claim = null;
      }

      isLoading = false;
      notifyListeners();

      return claim;
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve claim status.';
      notifyListeners();

      return null;
    }
  }

  // Retrieves all student claims for Pusat ADAB.
  // This method follows the getAllClaims() method stated in the SDD.
  Future<void> getAllClaims() async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final snapshot = await _firestore.collection('CoCurriculumClaim').get();

      claims = snapshot.docs
          .map((doc) => CoCurriculumClaimModel.fromFirestore(doc))
          .toList();

      claims.sort(
        (a, b) => b.submission_date.compareTo(a.submission_date),
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve claim list.';
      notifyListeners();
    }
  }

  // Retrieves only Pending Verification claims.
  // This method is used by AdabClaimListPage to show claims that require action.
  Future<List<CoCurriculumClaimModel>> getAllPendingClaims() async {
    await getAllClaims();

    return claims
        .where((claim) => claim.claim_status == 'Pending Verification')
        .toList();
  }

  // Retrieves selected claim detail using claim_id.
  // This method follows the getClaimDetail(claim_id) method stated in the SDD.
  Future<CoCurriculumClaimModel?> getClaimDetail(String claim_id) async {
    try {
      final doc = await _firestore
          .collection('CoCurriculumClaim')
          .doc(claim_id)
          .get();

      if (doc.exists) {
        claim = CoCurriculumClaimModel.fromFirestore(doc);
        notifyListeners();
        return claim;
      }

      return null;
    } catch (e) {
      error_message = 'Failed to retrieve claim detail.';
      notifyListeners();

      return null;
    }
  }

  // Approves a selected claim and adds 2 co-curriculum credits to the student.
  // Firestore transaction is used to update claim and student credit together.
  Future<void> approveClaim(
    String claim_id,
    String staff_id,
    String student_id,
  ) async {
    final claimRef = _firestore.collection('CoCurriculumClaim').doc(claim_id);
    final studentRef = _firestore.collection('Student').doc(student_id);

    await _firestore.runTransaction((transaction) async {
      final claimSnapshot = await transaction.get(claimRef);

      if (!claimSnapshot.exists) {
        throw Exception('Claim not found');
      }

      final claimData = claimSnapshot.data() as Map<String, dynamic>;
      final completedCount = claimData['completed_module_count'] ?? 0;

      if (completedCount < 4) {
        throw Exception('Student has not completed 4 modules');
      }

      transaction.update(claimRef, {
        'claim_status': 'Approved',
        'verified_by': staff_id,
        'verification_date': Timestamp.fromDate(DateTime.now()),
        'credit_awarded': 2,
      });

      transaction.update(studentRef, {
        'co_curriculum_credit': FieldValue.increment(2),
      });
    });

    notifyListeners();
  }

  // Rejects a selected claim and stores the rejection reason.
  Future<void> rejectClaim(
    String claim_id,
    String staff_id,
    String rejection_reason,
  ) async {
    await _firestore.collection('CoCurriculumClaim').doc(claim_id).update({
      'claim_status': 'Rejected',
      'verified_by': staff_id,
      'verification_date': Timestamp.fromDate(DateTime.now()),
      'rejection_reason': rejection_reason,
    });

    notifyListeners();
  }
}