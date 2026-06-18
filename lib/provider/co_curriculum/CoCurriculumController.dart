import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/co_curriculum/StudentModel.dart';
import '../../domain/co_curriculum/StudentCoCurriculumRecordModel.dart';
import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../domain/co_curriculum/CoCurriculumModuleModel.dart';

class CoCurriculumController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String error_message = '';

  StudentModel? student;
  CoCurriculumClaimModel? claim;

  List<StudentCoCurriculumRecordModel> records = [];
  List<CoCurriculumClaimModel> claims = [];
  List<CoCurriculumModuleModel> availableModules = [];

  Map<String, CoCurriculumModuleModel> modules = {};

  // OOP METHOD: Retrieves student entity detail from Firestore.
  Future<void> getStudentDetail(String student_id) async {
    try {
      final doc = await _firestore.collection('Student').doc(student_id).get();

      if (doc.exists) {
        student = StudentModel.fromFirestore(doc);
      } else {
        student = null;
      }

      notifyListeners();
    } catch (e) {
      error_message = 'Failed to retrieve student information.';
      notifyListeners();
    }
  }

  // OOP METHOD: Retrieves student co-curriculum records and module data.
  Future<void> getStudentRecords(String student_id) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      await getStudentDetail(student_id);
      await getCoCurriculumModules();

      final snapshot = await _firestore
          .collection('StudentCoCurriculumRecord')
          .where('student_id', isEqualTo: student_id)
          .get();

      records = snapshot.docs
          .map((doc) => StudentCoCurriculumRecordModel.fromFirestore(doc))
          .toList();

      records.sort((a, b) {
        final aDate = a.date_created ?? DateTime(2000);
        final bDate = b.date_created ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve co-curriculum records.';
      notifyListeners();
    }
  }

  // OOP METHOD: Retrieves all module entities and stores them in a map.
  Future<void> getCoCurriculumModules() async {
    try {
      final snapshot = await _firestore.collection('CoCurriculumModule').get();

      modules = {};

      for (var doc in snapshot.docs) {
        final module = CoCurriculumModuleModel.fromFirestore(doc);
        modules[module.module_id] = module;
      }

      notifyListeners();
    } catch (e) {
      error_message = 'Failed to retrieve co-curriculum modules.';
      notifyListeners();
    }
  }

  // OOP METHOD: Retrieves active co-curriculum modules for registration.
  Future<void> getAvailableModules() async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final snapshot = await _firestore.collection('CoCurriculumModule').get();

      final allModules = snapshot.docs
          .map((doc) => CoCurriculumModuleModel.fromFirestore(doc))
          .toList();

      availableModules = allModules.where((module) {
        return module.module_status.toLowerCase() == 'active';
      }).toList();

      availableModules.sort((a, b) {
        final aDate = a.module_date ?? DateTime(2100);
        final bDate = b.module_date ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

      modules = {
        for (final module in allModules) module.module_id: module,
      };

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to retrieve available modules.';
      notifyListeners();
    }
  }

  // OOP METHOD: Adds a new module entity created by Pusat ADAB.
  Future<String> addCoCurriculumModule({
    required String module_name,
    required String module_category,
    required int credit_value,
    required DateTime module_date,
    required String created_by,
  }) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final moduleRef = _firestore.collection('CoCurriculumModule').doc();

      final module = CoCurriculumModuleModel(
        module_id: moduleRef.id,
        module_name: module_name,
        module_category: module_category,
        credit_value: credit_value,
        module_status: 'Active',
        module_date: module_date,
        created_by: created_by,
        date_created: DateTime.now(),
      );

      await moduleRef.set(module.toFirestore());

      await getAvailableModules();

      isLoading = false;
      notifyListeners();

      return 'Module added successfully.';
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to add module.';
      notifyListeners();

      return 'Failed to add module.';
    }
  }

  // OOP METHOD: Registers a student for a selected co-curriculum module.
  Future<String> registerModule({
    required String student_id,
    required String module_id,
  }) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final duplicateSnapshot = await _firestore
          .collection('StudentCoCurriculumRecord')
          .where('student_id', isEqualTo: student_id)
          .where('module_id', isEqualTo: module_id)
          .get();

      if (duplicateSnapshot.docs.isNotEmpty) {
        isLoading = false;
        notifyListeners();
        return 'You have already registered this module.';
      }

      final recordRef =
          _firestore.collection('StudentCoCurriculumRecord').doc();

      final record = StudentCoCurriculumRecordModel(
        record_id: recordRef.id,
        student_id: student_id,
        module_id: module_id,
        completion_status: 'Registered',
        completion_date: null,
        date_created: DateTime.now(),
      );

      await recordRef.set(record.toFirestore());

      await getStudentRecords(student_id);

      isLoading = false;
      notifyListeners();

      return 'Module registered successfully.';
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to register module.';
      notifyListeners();

      return 'Failed to register module.';
    }
  }

  // OOP METHOD: Marks a registered module as completed after module date.
  Future<String> markModuleAsCompleted({
    required String student_id,
    required StudentCoCurriculumRecordModel record,
  }) async {
    try {
      isLoading = true;
      error_message = '';
      notifyListeners();

      final module = modules[record.module_id];

      if (module == null) {
        isLoading = false;
        notifyListeners();
        return 'Module information not found.';
      }

      if (!module.isModuleDateReached()) {
        isLoading = false;
        notifyListeners();
        return 'You can only mark this module as completed after the module date.';
      }

      await _firestore
          .collection('StudentCoCurriculumRecord')
          .doc(record.record_id)
          .update({
        'completion_status': 'Completed',
        'completion_date': Timestamp.fromDate(DateTime.now()),
      });

      await getStudentRecords(student_id);

      isLoading = false;
      notifyListeners();

      return 'Module marked as completed.';
    } catch (e) {
      isLoading = false;
      error_message = 'Failed to update module status.';
      notifyListeners();

      return 'Failed to update module status.';
    }
  }

  // OOP METHOD: Counts completed student module records.
  int getCompletedModuleCount() {
    return records.where((record) => record.isCompleted()).length;
  }

  // OOP METHOD: Counts registered student module records.
  int getRegisteredModuleCount() {
    return records.where((record) => record.completion_status == 'Registered').length;
  }

  // OOP METHOD: Checks whether student completed at least 4 modules.
  Future<bool> checkEligibility(String student_id) async {
    await getStudentRecords(student_id);

    return getCompletedModuleCount() >= 4;
  }

  // OOP METHOD: Checks duplicate pending or approved claims.
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

  // OOP METHOD: Submits a claim with Pending Verification status.
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

  // OOP METHOD: Retrieves the latest claim status for student.
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

  // OOP METHOD: Retrieves all claim records for Pusat ADAB queue.
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

  // OOP METHOD: Filters all pending verification claims.
  Future<List<CoCurriculumClaimModel>> getAllPendingClaims() async {
    await getAllClaims();

    return claims
        .where((claim) => claim.claim_status == 'Pending Verification')
        .toList();
  }

  // OOP METHOD: Retrieves selected claim detail by claim ID.
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

  // OOP METHOD: Approves claim, updates status and adds 2 credits.
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

      transaction.set(
        studentRef,
        {
          'student_id': student_id,
          'co_curriculum_credit': FieldValue.increment(2),
        },
        SetOptions(merge: true),
      );
    });

    notifyListeners();
  }

  // OOP METHOD: Rejects claim and stores rejection reason.
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