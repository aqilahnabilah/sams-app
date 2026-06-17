import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCoCurriculumRecordModel {
  // Entity attributes for StudentCoCurriculumRecord.
  // This model represents the co-curriculum module record completed by a student.
  final String record_id;
  final String student_id;
  final String module_id;
  final String completion_status;
  final DateTime? completion_date;
  final DateTime? date_created;

  const StudentCoCurriculumRecordModel({
    required this.record_id,
    required this.student_id,
    required this.module_id,
    required this.completion_status,
    this.completion_date,
    this.date_created,
  });

  // This factory method converts Firestore document data into StudentCoCurriculumRecordModel.
  factory StudentCoCurriculumRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StudentCoCurriculumRecordModel(
      record_id: data['record_id'] ?? doc.id,
      student_id: data['student_id'] ?? '',
      module_id: data['module_id'] ?? '',
      completion_status: data['completion_status'] ?? '',
      completion_date: convertNullableTimestampToDateTime(
        data['completion_date'],
      ),
      date_created: convertNullableTimestampToDateTime(
        data['date_created'],
      ),
    );
  }

  // This method converts StudentCoCurriculumRecordModel into Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'record_id': record_id,
      'student_id': student_id,
      'module_id': module_id,
      'completion_status': completion_status,
      'completion_date': completion_date != null
          ? Timestamp.fromDate(completion_date!)
          : null,
      'date_created': date_created != null
          ? Timestamp.fromDate(date_created!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // This method checks whether the student has completed the module.
  bool isCompleted() {
    return completion_status == 'Completed';
  }

  // This method converts nullable Firestore Timestamp into nullable DateTime.
  static DateTime? convertNullableTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }
}