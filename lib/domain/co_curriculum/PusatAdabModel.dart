import 'package:cloud_firestore/cloud_firestore.dart';

class PusatAdabModel {
  final String staff_id;
  final String staff_name;
  final String staff_email;
  final String department;
  final String role;
  final String account_status;

  PusatAdabModel({
    required this.staff_id,
    required this.staff_name,
    required this.staff_email,
    required this.department,
    required this.role,
    required this.account_status,
  });

  factory PusatAdabModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PusatAdabModel(
      staff_id: data['staff_id'] ?? doc.id,
      staff_name: data['staff_name'] ?? '',
      staff_email: data['staff_email'] ?? '',
      department: data['department'] ?? 'Pusat ADAB',
      role: data['role'] ?? 'Pusat ADAB',
      account_status: data['account_status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'staff_id': staff_id,
      'staff_name': staff_name,
      'staff_email': staff_email,
      'department': department,
      'role': role,
      'account_status': account_status,
    };
  }

  bool isActive() {
    return account_status == 'Active';
  }
}