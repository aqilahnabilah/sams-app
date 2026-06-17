import 'package:cloud_firestore/cloud_firestore.dart';

class PusatAdabModel {
  // Entity attributes for PusatAdab.
  // This model represents Pusat ADAB staff who verifies co-curriculum claims.
  final String staff_id;
  final String staff_name;
  final String staff_email;
  final String department;
  final String role;
  final String account_status;
  final DateTime? date_created;

  const PusatAdabModel({
    required this.staff_id,
    required this.staff_name,
    required this.staff_email,
    required this.department,
    required this.role,
    required this.account_status,
    this.date_created,
  });

  // This factory method converts Firestore document data into PusatAdabModel.
  factory PusatAdabModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PusatAdabModel(
      staff_id: data['staff_id'] ?? doc.id,
      staff_name: data['staff_name'] ?? '',
      staff_email: data['staff_email'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? '',
      account_status: data['account_status'] ?? '',
      date_created: convertNullableTimestampToDateTime(
        data['date_created'],
      ),
    );
  }

  // This method converts PusatAdabModel into Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'staff_id': staff_id,
      'staff_name': staff_name,
      'staff_email': staff_email,
      'department': department,
      'role': role,
      'account_status': account_status,
      'date_created': date_created != null
          ? Timestamp.fromDate(date_created!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // This method checks whether Pusat ADAB account is active.
  bool isActive() {
    return account_status == 'Active';
  }

  // This method checks whether the staff role is Pusat ADAB.
  bool isPusatAdabStaff() {
    return role == 'Pusat ADAB';
  }

  // This method converts nullable Firestore Timestamp into nullable DateTime.
  static DateTime? convertNullableTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }
}