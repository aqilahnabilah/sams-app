import 'package:cloud_firestore/cloud_firestore.dart';

class CoCurriculumModuleModel {
  // Entity attributes for CoCurriculumModule.
  // This model represents co-curriculum module information.
  final String module_id;
  final String module_name;
  final String module_category;
  final int credit_value;
  final String module_status;
  final DateTime? date_created;

  const CoCurriculumModuleModel({
    required this.module_id,
    required this.module_name,
    required this.module_category,
    required this.credit_value,
    required this.module_status,
    this.date_created,
  });

  // This factory method converts Firestore document data into CoCurriculumModuleModel.
  factory CoCurriculumModuleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CoCurriculumModuleModel(
      module_id: data['module_id'] ?? doc.id,
      module_name: data['module_name'] ?? '',
      module_category: data['module_category'] ?? '',
      credit_value: data['credit_value'] ?? 0,
      module_status: data['module_status'] ?? '',
      date_created: convertNullableTimestampToDateTime(
        data['date_created'],
      ),
    );
  }

  // This method converts CoCurriculumModuleModel into Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'module_id': module_id,
      'module_name': module_name,
      'module_category': module_category,
      'credit_value': credit_value,
      'module_status': module_status,
      'date_created': date_created != null
          ? Timestamp.fromDate(date_created!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // This method checks whether the co-curriculum module is active.
  bool isActive() {
    return module_status == 'Active';
  }

  // This method converts nullable Firestore Timestamp into nullable DateTime.
  static DateTime? convertNullableTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }
}