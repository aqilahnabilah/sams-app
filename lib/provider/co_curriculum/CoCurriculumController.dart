import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/co_curriculum/StudentCoCurriculumRecordModel.dart';
import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../domain/co_curriculum/CoCurriculumModuleModel.dart';

class CoCurriculumController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String error_message = '';

  List<StudentCoCurriculumRecordModel> records = [];
  Map<String, CoCurriculumModuleModel> modules = {};
  CoCurriculumClaimModel? claim;

  Future<void> getStudentRecords(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

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

  int getCompletedModuleCount() {
    return records.where((record) => record.isCompleted()).length;
  }

  Future<bool> checkEligibility(String student_id) async {
    await getStudentRecords(student_id);

    return getCompletedModuleCount() >= 4;
  }

  Future<bool> checkDuplicateClaim(String student_id) async {
    final snapshot = await _firestore
        .collection('CoCurriculumClaim')
        .where('student_id', isEqualTo: student_id)
        .where('claim_status', whereIn: ['Pending Verification', 'Approved'])
        .get();

    return snapshot.docs.isNotEmpty;
  }

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

  Future<void> getClaimStatus(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final snapshot = await _firestore
          .collection('CoCurriculumClaim')
          .where('student_id', isEqualTo: student_id)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final claims = snapshot.docs
            .map((doc) => CoCurriculumClaimModel.fromFirestore(doc))
            .toList();

        claims.sort(
          (a, b) => b.submission_date.compareTo(a.submission_date),
        );

        claim = claims.first;
      } else {
        claim = null;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve claim status.';
      notifyListeners();
    }
  }

  Future<List<CoCurriculumClaimModel>> getAllPendingClaims() async {
    final snapshot = await _firestore
        .collection('CoCurriculumClaim')
        .where('claim_status', isEqualTo: 'Pending Verification')
        .get();

    return snapshot.docs
        .map((doc) => CoCurriculumClaimModel.fromFirestore(doc))
        .toList();
  }

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