import 'package:cloud_firestore/cloud_firestore.dart';

class CoCurriculumModuleModel {
  final String module_id;
  final String module_name;
  final String module_category;
  final int credit_value;
  final String module_status;

  CoCurriculumModuleModel({
    required this.module_id,
    required this.module_name,
    required this.module_category,
    required this.credit_value,
    required this.module_status,
  });

  factory CoCurriculumModuleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CoCurriculumModuleModel(
      module_id: data['module_id'] ?? doc.id,
      module_name: data['module_name'] ?? '',
      module_category: data['module_category'] ?? '',
      credit_value: data['credit_value'] ?? 0,
      module_status: data['module_status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'module_id': module_id,
      'module_name': module_name,
      'module_category': module_category,
      'credit_value': credit_value,
      'module_status': module_status,
    };
  }

  bool isActive() {
    return module_status == 'Active';
  }
}