import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/Attendance/ClassSessionModel.dart';
import '../../domain/Attendance/ClassCodeModel.dart';
import '../../utils/constants.dart';

/// SAMS-PACK-308 — Class code generation and validation.
class ClassCodeController extends ChangeNotifier {
  final FirebaseFirestore _db;
  final _random = Random.secure();

  ClassCodeController({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  ClassCodeModel? _activeCode;
  String? _errorMessage;
  bool _isLoading = false;

  ClassCodeModel? get activeCode => _activeCode;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  String? _currentClassSessionId;
  String? _currentStaffId;
  String _sessionStatus = 'Closed';
  bool _requiresLocation = true;

  String get sessionStatus => _sessionStatus;
  bool get requiresLocation => _requiresLocation;

  /// Generates a new unique class code for the specific session.
  Future<ClassCodeModel?> generateClassCode(
    String classSessionId,
    String staffId,
  ) async {
    _currentClassSessionId = classSessionId;
    _currentStaffId = staffId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sync initial session status
      final doc = await _db
          .collection(FirestoreCollections.classSessions)
          .doc(classSessionId)
          .get();
      if (doc.exists) {
        _sessionStatus = doc.data()?['session_status'] ?? 'Closed';
        _requiresLocation = doc.data()?['requires_location'] ?? true;
      }

      await deactivatePreviousCode(classSessionId);
      
      String code = _generateRandomCode();
      bool unique = false;
      int attempts = 0;
      while (!unique && attempts < 5) {
        final existing = await _db
            .collection(FirestoreCollections.attendanceCodes)
            .where('class_code', isEqualTo: code)
            .where('is_active', isEqualTo: true)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) {
          unique = true;
        } else {
          code = _generateRandomCode();
          attempts++;
        }
      }

      final now = DateTime.now();
      final expiredAt = now.add(kClassCodeExpiry);
      final codeId = _db.collection(FirestoreCollections.attendanceCodes).doc().id;

      final model = ClassCodeModel(
        codeId: codeId,
        classSessionId: classSessionId,
        staffId: staffId,
        classCode: code,
        generatedAt: now,
        expiredAt: expiredAt,
        isActive: true,
      );

      await _db
          .collection(FirestoreCollections.attendanceCodes)
          .doc(codeId)
          .set(model.toMap());

      _activeCode = model;
      return model;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the currently active code for a class session.
  Future<ClassCodeModel?> fetchActiveCode(String classSessionId) async {
    _currentClassSessionId = classSessionId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _db
          .collection(FirestoreCollections.classSessions)
          .doc(classSessionId)
          .get();
      if (doc.exists) {
        _sessionStatus = doc.data()?['session_status'] ?? 'Closed';
        _requiresLocation = doc.data()?['requires_location'] ?? true;
      }

      final snapshot = await _db
          .collection(FirestoreCollections.attendanceCodes)
          .where('class_session_id', isEqualTo: classSessionId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final model = ClassCodeModel.fromMap(snapshot.docs.first.data());
        _activeCode = model;
        _currentStaffId = model.staffId;
        return model;
      }
      _activeCode = null;
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Regenerates the code for the current session context.
  Future<ClassCodeModel?> regenerateClassCode() async {
    if (_currentClassSessionId == null || _currentStaffId == null) {
      _errorMessage = 'No active session context for regeneration';
      notifyListeners();
      return null;
    }
    return generateClassCode(_currentClassSessionId!, _currentStaffId!);
  }

  /// Deactivates all existing codes for a session in the database.
  Future<void> deactivatePreviousCode(String classSessionId) async {
    final snapshot = await _db
        .collection(FirestoreCollections.attendanceCodes)
        .where('class_session_id', isEqualTo: classSessionId)
        .where('is_active', isEqualTo: true)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'is_active': false});
    }
    await batch.commit();
  }

  /// Validates a code input from a student.
  Future<ClassCodeModel?> validateClassCode(String inputCode) async {
    final normalized = inputCode.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final snapshot = await _db
        .collection(FirestoreCollections.attendanceCodes)
        .where('class_code', isEqualTo: normalized)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final model = ClassCodeModel.fromMap(snapshot.docs.first.data());
    
    // Validate that the linked session is still open.
    final sessionDoc = await _db
        .collection(FirestoreCollections.classSessions)
        .doc(model.classSessionId)
        .get();

    if (!sessionDoc.exists) return null;
    final session = ClassSessionModel.fromMap(sessionDoc.data()!);
    if (!session.isOpen()) return null;

    return model;
  }

  /// Generates a human-readable random code string.
  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String pick(int length) {
      return List.generate(
        length,
        (_) => chars[_random.nextInt(chars.length)],
      ).join();
    }

    return '${pick(3)}-${pick(2)}';
  }

  /// Local cleanup of the active code state.
  void clearActiveCode() {
    _activeCode = null;
    notifyListeners();
  }

  /// Toggles the operational state (Open/Closed) of a class session.
  /// Saves full metadata to ensure it appears in Lecturer History.
  Future<void> toggleSessionStatus(ClassSessionModel session) async {
    try {
      final newStatus = _sessionStatus == 'Open' ? 'Closed' : 'Open';
      
      final updatedModel = ClassSessionModel(
        classSessionId: session.classSessionId,
        staffId: session.staffId,
        subjectCode: session.subjectCode,
        subjectName: session.subjectName,
        classSection: session.classSection,
        classDate: session.classDate,
        startTime: session.startTime,
        endTime: session.endTime,
        sessionStatus: newStatus,
        requiresLocation: _requiresLocation,
      );

      await _db
          .collection(FirestoreCollections.classSessions)
          .doc(session.classSessionId)
          .set(updatedModel.toMap(), SetOptions(merge: true));

      _sessionStatus = newStatus;
      if (_sessionStatus == 'Closed') {
        _activeCode = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggleSessionStatus error: $e');
    }
  }

  /// Toggles the location verification enforcement flag for a session.
  Future<void> toggleLocationRequirement(String classSessionId) async {
    try {
      final newValue = !_requiresLocation;
      await _db
          .collection(FirestoreCollections.classSessions)
          .doc(classSessionId)
          .set({'requires_location': newValue}, SetOptions(merge: true));
      _requiresLocation = newValue;
      notifyListeners();
    } catch (e) {
      debugPrint('toggleLocationRequirement error: $e');
    }
  }
}
