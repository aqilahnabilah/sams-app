/// [StudentModel] represents the core profile of a student within the SAMS system.
/// It includes academic details and tracks if the student is currently restricted (blocked)
/// from academic activities due to unpaid fees.
class StudentModel {
  // --- Basic Identity and Contact ---
  /// Unique student identifier (e.g., CB23026).
  final String studentId;
  /// The student's full registered name.
  final String fullName;
  /// Institutional email address.
  final String studentEmail;
  /// Contact phone number.
  final String phoneNo;

  // --- Academic Standing ---
  /// Short code for the student's program (e.g., BCS).
  final String programCode;
  /// The full descriptive name of the degree program.
  final String programName;
  /// The faculty the student belongs to (e.g., FK).
  final String currentSem;

  // --- Enrollment and Access Status ---
  /// General enrollment status (e.g., Active, Graduated, Withdrawn).
  final String status;
  /// Policy-driven flag indicating if academic access is restricted.
  /// True if the student has outstanding fees after Week 5.
  bool isBlocked;

  /// Standard constructor for initializing student records.
  StudentModel({
    required this.studentId,
    required this.fullName,
    required this.studentEmail,
    required this.phoneNo,
    required this.programCode,
    required this.programName,
    required this.faculty,
    required this.currentSem,
    required this.status,
    required this.isBlocked,
  });

  /// The faculty to which the program belongs.
  final String faculty;

  /// Converts the [StudentModel] instance into a [Map] for Cloud Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'student_email': studentEmail,
      'phone_no': phoneNo,
      'program_code': programCode,
      'program_name': programName,
      'faculty': faculty,
      'current_sem': currentSem,
      'status': status,
      'is_blocked': isBlocked,
    };
  }

  /// Creates a [StudentModel] instance from a [Map] retrieved from Firestore.
  /// Ensures safe fallback values for missing data.
  factory StudentModel.fromFirestore(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['student_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      studentEmail: map['student_email']?.toString() ?? '',
      phoneNo: map['phone_no']?.toString() ?? '',
      programCode: map['program_code']?.toString() ?? '',
      programName: map['program_name']?.toString() ?? '',
      faculty: map['faculty']?.toString() ?? '',
      currentSem: map['current_sem']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      isBlocked: map['is_blocked'] == true,
    );
  }

  /// Updates the student's academic block status.
  void updateBlockStatus(bool status) {
    isBlocked = status;
  }
}
