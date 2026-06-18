/// Model for logged-in user information.
class UserModel {
  // Canonical role names used by the app.
  static const String roleStudent = 'Student';
  static const String roleTreasury = 'Treasury';
  static const String roleLecturer = 'Lecturer';
  static const String rolePusatAdab = 'Pusat Adab';
  static const String roleFacultyRegistrar = 'Faculty Registrar';

  final String userId; // Student ID / Staff ID, e.g. CB23026
  final String username; // Full name
  final String role;

  UserModel({
    required this.userId,
    required this.username,
    required this.role,
  });

  /// Converts older/typed role values into one consistent value.
  static String normalizeRole(String? role) {
    final value = (role ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (value == 'student') return roleStudent;
    if (value == 'lecturer') return roleLecturer;
    if (value == 'treasury' || value == 'treasury_officer') return roleTreasury;
    if (value == 'faculty_registrar' || value == 'registrar') {
      return roleFacultyRegistrar;
    }
    if (value == 'pusat_adab' ||
        value == 'pusatadab' ||
        value == 'adab' ||
        value == 'adab_staff' ||
        value == 'staff_adab') {
      return rolePusatAdab;
    }

    return role ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'name': username,
      'role': normalizeRole(role),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> map) {
    return UserModel(
      userId: (map['user_id'] ?? map['userId'] ?? map['student_id'] ?? map['staff_id'] ?? map['email'] ?? '').toString(),
      username: (map['username'] ?? map['name'] ?? map['full_name'] ?? map['staff_name'] ?? '').toString(),
      role: normalizeRole(map['role']?.toString()),
    );
  }
}
