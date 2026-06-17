import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCoCurriculumRecordModel {
  final String record_id;
  final String student_id;
  final String module_id;
  final String completion_status;
  final DateTime completion_date;
  final DateTime? date_created;

  StudentCoCurriculumRecordModel({
    required this.record_id,
    required this.student_id,
    required this.module_id,
    required this.completion_status,
    required this.completion_date,
    this.date_created,
  });

  factory StudentCoCurriculumRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StudentCoCurriculumRecordModel(
      record_id: data['record_id'] ?? doc.id,
      student_id: data['student_id'] ?? '',
      module_id: data['module_id'] ?? '',
      completion_status: data['completion_status'] ?? '',
      completion_date: data['completion_date'] == null
          ? DateTime.now()
          : (data['completion_date'] as Timestamp).toDate(),
      date_created: data['date_created'] == null
          ? null
          : (data['date_created'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'record_id': record_id,
      'student_id': student_id,
      'module_id': module_id,
      'completion_status': completion_status,
      'completion_date': Timestamp.fromDate(completion_date),
      'date_created': date_created == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(date_created!),
    };
  }

  bool isCompleted() {
    return completion_status == 'Completed';
  }
}