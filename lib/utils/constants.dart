class FirestoreCollections {
  static const String users = 'users';
  static const String fees = 'fees';
  static const String payments = 'payments';
  static const String students = 'students';
  static const String locations = 'locations';
  static const String classSessions = 'class_sessions';
  static const String attendanceRecords = 'attendance_records';
  static const String attendanceCodes = 'attendance_codes'; // Matches ClassCodeController
}

const Duration kClassCodeExpiry = Duration(hours: 3);
