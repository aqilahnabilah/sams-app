/// [TreasuryModel] represents a staff member from the Treasury department.
/// These users are responsible for auditing and verifying payment submissions from students.
class TreasuryModel {
  // --- Roles ---
  /// Constant identifier for the Treasury role.
  static const String roleTreasury = 'Treasury';

  // --- Identity and Contact ---
  /// Unique staff or worker identifier.
  final String staffId;
  /// The full name of the treasury officer.
  final String staffName;
  /// Institutional email address for the staff.
  final String staffEmail;

  // --- Organizational Details ---
  /// The specific department or division the staff belongs to.
  final String department;
  /// The functional role assigned to the staff member.
  final String role;

  /// Standard constructor for initializing treasury officer records.
  TreasuryModel({
    required this.staffId,
    required this.staffName,
    required this.staffEmail,
    required this.department,
    required this.role,
  });

  /// Converts the [TreasuryModel] instance into a [Map] for Cloud Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'staff_email': staffEmail,
      'department': department,
      'role': role,
    };
  }

  /// Creates a [TreasuryModel] instance from a [Map] retrieved from Cloud Firestore.
  factory TreasuryModel.fromFirestore(Map<String, dynamic> map) {
    return TreasuryModel(
      staffId: map['staff_id']?.toString() ?? '',
      staffName: map['staff_name']?.toString() ?? '',
      staffEmail: map['staff_email']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
    );
  }

  /// Verifies if the staff member has the appropriate role to process payments.
  bool canVerify() {
    return role == roleTreasury;
  }
}
