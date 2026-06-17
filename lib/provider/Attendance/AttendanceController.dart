import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../utils/constants.dart';
import '../../utils/haversine.dart';
import 'ClassCodeController.dart';
import 'LocationVerificationController.dart';

/// SAMS-PACK-307 — Attendance submission orchestration.
class AttendanceController extends ChangeNotifier {
  final FirebaseFirestore _db;
  final LocationVerification _locationVerification;
  final ClassCodeController _classCodeController;

  AttendanceController({
    FirebaseFirestore? db,
    required LocationVerification locationVerification,
    required ClassCodeController classCodeController,
  })  : _db = db ?? FirebaseFirestore.instance,
        _locationVerification = locationVerification,
        _classCodeController = classCodeController;

  bool _isSubmitting = false;
  String? _lastResult;
  List<AttendanceRecordModel> _sessionRecords = [];
  StreamSubscription? _attendanceSubscription;

  bool get isSubmitting => _isSubmitting;
  String? get lastResult => _lastResult;
  List<AttendanceRecordModel> get sessionRecords => _sessionRecords;

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> submitAttendance({
    required String studentId,
    required String codeInput,
  }) async {
    _isSubmitting = true;
    _lastResult = null;
    notifyListeners();

    try {
      final codeModel =
          await _classCodeController.validateClassCode(codeInput);
      if (codeModel == null) {
        _lastResult = 'invalid_code';
        return {'status': 'invalid_code'};
      }

      final sessionDoc = await _db
          .collection(FirestoreCollections.classSessions)
          .doc(codeModel.classSessionId)
          .get();
      
      bool requiresLocation = true;
      String subjectCode = 'Subject';
      double? sessionLat;
      double? sessionLng;
      
      if (sessionDoc.exists) {
        final session = ClassSessionModel.fromMap(sessionDoc.data()!);
        subjectCode = session.subjectCode;
        requiresLocation = session.requiresLocation;
        sessionLat = session.latitude;
        sessionLng = session.longitude;

        if (!session.isOpen()) {
          _lastResult = 'invalid_code';
          return {'status': 'invalid_code'};
        }
      }

      if (requiresLocation) {
        final gpsOk = await _locationVerification.checkGPSPermission();
        if (!gpsOk) {
          _lastResult = 'gps_denied';
          return {'status': 'gps_denied'};
        }

        // 1. Get current position and verify.
        // We pass target location to LocationVerification so it can update its status message.
        await _locationVerification.verifyCurrentLocation(
          targetLat: sessionLat,
          targetLon: sessionLng,
        );

        if (_locationVerification.currentLatitude == null) {
          _lastResult = 'gps_denied';
          return {'status': 'gps_denied'};
        }
        
        // 2. If session has a specific location, match against it. 
        // Otherwise fallback to campus default.
        if (sessionLat != null && sessionLng != null) {
          final dist = haversineDistanceMeters(
            lat1: _locationVerification.currentLatitude!,
            lon1: _locationVerification.currentLongitude!,
            lat2: sessionLat,
            lon2: sessionLng,
          );
          
          debugPrint('SAMS_DEBUG: Student is $dist meters from Lecturer.');
          
          if (dist > 1000) { // 1,000 meters tolerance from lecturer
            _lastResult = 'outside_campus';
            return {'status': 'outside_campus'};
          }
        } else {
          debugPrint('SAMS_DEBUG: Session has no saved location. Falling back to Campus Geofence.');
          // Fallback to campus geofence if session location isn't set
          if (!_locationVerification.isOnCampus) {
            debugPrint('SAMS_DEBUG: Student is NOT on campus (dist: ${_locationVerification.lastDistanceMeters}m).');
            _lastResult = 'outside_campus';
            return {'status': 'outside_campus'};
          }
        }
      }

      final duplicate = await _db
          .collection(FirestoreCollections.attendanceRecords)
          .where('student_id', isEqualTo: studentId)
          .where('class_session_id', isEqualTo: codeModel.classSessionId)
          .limit(1)
          .get();

      if (duplicate.docs.isNotEmpty) {
        _lastResult = 'duplicate';
        return {
          'status': 'duplicate',
          'subjectCode': subjectCode,
        };
      }

      final attendanceId =
          _db.collection(FirestoreCollections.attendanceRecords).doc().id;
      final locationId =
          _locationVerification.activeLocation?.locationId ?? '';

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

      _lastResult = 'success';
      return {
        'status': 'success',
        'subjectCode': subjectCode,
      };
    } catch (e) {
      debugPrint('submitAttendance error: $e');
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
          
      // Manual sort
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      
      _sessionRecords = records;
      notifyListeners();
    }, onError: (e) {
      debugPrint('listenToSessionAttendance error: $e');
      _sessionRecords = [];
      notifyListeners();
    });
  }

  void stopListeningToSessionAttendance() {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = null;
    _sessionRecords = [];
    notifyListeners();
  }

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
          
      // Manual sort to avoid needing a Firestore composite index
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      
      return records;
    } catch (e) {
      debugPrint('fetchStudentHistory error: $e');
      return [];
    }
  }

  Future<List<ClassSessionModel>> fetchLecturerSessions(String staffId) async {
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.classSessions)
          .where('staff_id', isEqualTo: staffId)
          .get();

      final sessions = snapshot.docs
          .map((d) => ClassSessionModel.fromMap(d.data()))
          .toList();
      
      // Sort by date/time (if possible)
      sessions.sort((a, b) => b.classDate.compareTo(a.classDate));
      
      return sessions;
    } catch (e) {
      debugPrint('fetchLecturerSessions error: $e');
      return [];
    }
  }

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
      debugPrint('fetchSubjectSessions error: $e');
      return [];
    }
  }

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

  Future<void> toggleSessionStatus(ClassSessionModel session) async {
    try {
      final newStatus = session.isOpen() ? 'Closed' : 'Open';
      await _db
          .collection(FirestoreCollections.classSessions)
          .doc(session.classSessionId)
          .update({'session_status': newStatus});
      notifyListeners();
    } catch (e) {
      debugPrint('toggleSessionStatus error: $e');
    }
  }
}
