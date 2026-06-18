import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../utils/constants.dart';
import 'ClassCodeController.dart';
import 'LocationVerificationController.dart';

/// SAMS-PACK-307 — Attendance submission orchestration.
class AttendanceController extends ChangeNotifier {
  final FirebaseFirestore _db;
  LocationVerification _locationVerification;
  ClassCodeController _classCodeController;
  bool _isDisposed = false;

  AttendanceController({
    FirebaseFirestore? db,
    required LocationVerification locationVerification,
    required ClassCodeController classCodeController,
  })  : _db = db ?? FirebaseFirestore.instance,
        _locationVerification = locationVerification,
        _classCodeController = classCodeController;

  /// Updates the controller's dependencies without disposing the instance.
  void update({
    required LocationVerification locationVerification,
    required ClassCodeController classCodeController,
  }) {
    if (_isDisposed) return;
    _locationVerification = locationVerification;
    _classCodeController = classCodeController;
  }

  bool _isSubmitting = false;
  String? _lastResult;
  List<AttendanceRecordModel> _sessionRecords = [];
  StreamSubscription? _attendanceSubscription;

  bool get isSubmitting => _isSubmitting;
  String? get lastResult => _lastResult;
  List<AttendanceRecordModel> get sessionRecords => _sessionRecords;

  @override
  void dispose() {
    _isDisposed = true;
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Processes a student's check-in attempt.
  /// Verifies the class code and ensures the student is within the UMPSA area.
  Future<Map<String, dynamic>> submitAttendance({
    required String studentId,
    required String codeInput,
  }) async {
    _isSubmitting = true;
    _lastResult = null;
    notifyListeners();

    try {
      debugPrint('SAMS_DEBUG: Starting attendance submission for $studentId');
      
      // 1. Validate the class code
      final codeModel =
          await _classCodeController.validateClassCode(codeInput);
      if (codeModel == null) {
        debugPrint('SAMS_DEBUG: Invalid code provided: $codeInput');
        _lastResult = 'invalid_code';
        return {'status': 'invalid_code'};
      }

      // 2. Fetch session context
      final sessionDoc = await _db
          .collection(FirestoreCollections.classSessions)
          .doc(codeModel.classSessionId)
          .get();
      
      bool requiresLocation = true;
      String subjectCode = 'Subject';
      
      if (sessionDoc.exists) {
        final session = ClassSessionModel.fromMap(sessionDoc.data()!);
        subjectCode = session.subjectCode;
        requiresLocation = session.requiresLocation;

        if (!session.isOpen()) {
          debugPrint('SAMS_DEBUG: Session is closed for ID: ${codeModel.classSessionId}');
          _lastResult = 'invalid_code';
          return {'status': 'invalid_code'};
        }
      }

      // 3. Location Verification (UMPSA Geofence Only)
      if (requiresLocation) {
        final gpsOk = await _locationVerification.checkGPSPermission();
        if (!gpsOk) {
          debugPrint('SAMS_DEBUG: GPS permission denied or service disabled.');
          _lastResult = 'gps_denied';
          return {'status': 'gps_denied'};
        }

        // Verify that the student is physically on campus.
        await _locationVerification.verifyCurrentLocation();

        if (!_locationVerification.isOnCampus) {
          debugPrint('SAMS_DEBUG: Student is NOT on campus (dist: ${_locationVerification.lastDistanceMeters}m).');
          _lastResult = 'outside_campus';
          return {'status': 'outside_campus'};
        }
      }

      // 4. Check for duplicate submission
      final duplicate = await _db
          .collection(FirestoreCollections.attendanceRecords)
          .where('student_id', isEqualTo: studentId)
          .where('class_session_id', isEqualTo: codeModel.classSessionId)
          .limit(1)
          .get();

      if (duplicate.docs.isNotEmpty) {
        debugPrint('SAMS_DEBUG: Duplicate check-in detected for $studentId');
        _lastResult = 'duplicate';
        return {
          'status': 'duplicate',
          'subjectCode': subjectCode,
        };
      }

      // 5. Create Attendance Record
      final attendanceId =
          _db.collection(FirestoreCollections.attendanceRecords).doc().id;
      final locationId =
          _locationVerification.activeLocation?.locationId ?? 'UMPSA';

      final record = AttendanceRecordModel(
        attendanceId: attendanceId,
        classSessionId: codeModel.classSessionId,
        codeId: codeModel.codeId,
        studentId: studentId,
        locationId: locationId,
        checkInTime: DateTime.now(),
        latitude: _locationVerification.currentLatitude ?? 0,
        longitude: _locationVerification.currentLongitude ?? 0,
        attendanceStatus: 'Present',
        remarks: '',
      );

      await _db
          .collection(FirestoreCollections.attendanceRecords)
          .doc(attendanceId)
          .set(record.toMap());

      debugPrint('SAMS_DEBUG: Attendance successfully recorded: $attendanceId');
      _lastResult = 'success';
      return {
        'status': 'success',
        'subjectCode': subjectCode,
      };
    } catch (e) {
      debugPrint('SAMS_ERROR: submitAttendance error: $e');
      if (e is FirebaseException) {
        _lastResult = 'db_error';
        return {'status': 'db_error'};
      } else {
        _lastResult = 'invalid_code';
        return {'status': 'invalid_code'};
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Listens to real-time check-ins for a specific class session.
  void listenToSessionAttendance(String classSessionId) {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = _db
        .collection(FirestoreCollections.attendanceRecords)
        .where('class_session_id', isEqualTo: classSessionId)
        .snapshots()
        .listen((snapshot) {
      final records = snapshot.docs
          .map((d) => AttendanceRecordModel.fromMap(d.data()))
          .toList();
          
      // Sort newest first
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      
      _sessionRecords = records;
      notifyListeners();
    }, onError: (e) {
      debugPrint('SAMS_ERROR: listenToSessionAttendance error: $e');
      _sessionRecords = [];
      notifyListeners();
    });
  }

  /// Stops the real-time check-in stream.
  void stopListeningToSessionAttendance() {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = null;
    _sessionRecords = [];
    notifyListeners();
  }

  /// Fetches the check-in history for a specific student.
  Future<List<AttendanceRecordModel>> fetchStudentHistory(
    String studentId,
  ) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.attendanceRecords)
          .where('student_id', isEqualTo: studentId)
          .get();

      final records = snapshot.docs
          .map((d) => AttendanceRecordModel.fromMap(d.data()))
          .toList();
          
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      
      return records;
    } catch (e) {
      debugPrint('SAMS_ERROR: fetchStudentHistory error: $e');
      return [];
    }
  }

  /// Retrieves all class sessions created by a specific staff member.
  Future<List<ClassSessionModel>> fetchLecturerSessions(String staffId) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.classSessions)
          .where('staff_id', isEqualTo: staffId)
          .get();

      final sessions = snapshot.docs
          .map((d) => ClassSessionModel.fromMap(d.data()))
          .toList();
      
      sessions.sort((a, b) => b.classDate.compareTo(a.classDate));
      
      return sessions;
    } catch (e) {
      debugPrint('SAMS_ERROR: fetchLecturerSessions error: $e');
      return [];
    }
  }

  /// Retrieves sessions for a specific subject taught by a staff member.
  Future<List<ClassSessionModel>> fetchSubjectSessions(String staffId, String subjectCode) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.classSessions)
          .where('staff_id', isEqualTo: staffId)
          .where('subject_code', isEqualTo: subjectCode)
          .get();

      final sessions = snapshot.docs
          .map((d) => ClassSessionModel.fromMap(d.data()))
          .toList();
          
      sessions.sort((a, b) => b.classDate.compareTo(a.classDate));
      return sessions;
    } catch (e) {
      debugPrint('SAMS_ERROR: fetchSubjectSessions error: $e');
      return [];
    }
  }

  /// Returns the total number of students who checked in for a session.
  Future<int> getSessionAttendanceCount(String classSessionId) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.attendanceRecords)
          .where('class_session_id', isEqualTo: classSessionId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Toggles the operational state (Open/Closed) of a class session.
  Future<void> toggleSessionStatus(ClassSessionModel session) async {
    try {
      final newStatus = session.isOpen() ? 'Closed' : 'Open';
      await _db
          .collection(FirestoreCollections.classSessions)
          .doc(session.classSessionId)
          .update({'session_status': newStatus});
      notifyListeners();
    } catch (e) {
      debugPrint('SAMS_ERROR: toggleSessionStatus error: $e');
    }
  }
}
