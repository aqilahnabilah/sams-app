import 'package:cloud_firestore/cloud_firestore.dart';

class CoCurriculumClaimModel {
  final String claim_id;
  final String student_id;
  final int completed_module_count;
  final String claim_status;
  final DateTime submission_date;
  final String? verified_by;
  final DateTime? verification_date;
  final String? rejection_reason;
  final int credit_awarded;
  final DateTime? date_created;

  CoCurriculumClaimModel({
    required this.claim_id,
    required this.student_id,
    required this.completed_module_count,
    required this.claim_status,
    required this.submission_date,
    this.verified_by,
    this.verification_date,
    this.rejection_reason,
    this.credit_awarded = 2,
    this.date_created,
  });

  factory CoCurriculumClaimModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CoCurriculumClaimModel(
      claim_id: data['claim_id'] ?? doc.id,
      student_id: data['student_id'] ?? '',
      completed_module_count: data['completed_module_count'] ?? 0,
      claim_status: data['claim_status'] ?? 'Pending Verification',
      submission_date: data['submission_date'] == null
          ? DateTime.now()
          : (data['submission_date'] as Timestamp).toDate(),
      verified_by: data['verified_by'],
      verification_date: data['verification_date'] == null
          ? null
          : (data['verification_date'] as Timestamp).toDate(),
      rejection_reason: data['rejection_reason'],
      credit_awarded: data['credit_awarded'] ?? 2,
      date_created: data['date_created'] == null
          ? null
          : (data['date_created'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'claim_id': claim_id,
      'student_id': student_id,
      'completed_module_count': completed_module_count,
      'claim_status': claim_status,
      'submission_date': Timestamp.fromDate(submission_date),
      'verified_by': verified_by,
      'verification_date': verification_date == null
          ? null
          : Timestamp.fromDate(verification_date!),
      'rejection_reason': rejection_reason,
      'credit_awarded': credit_awarded,
      'date_created': date_created == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(date_created!),
    };
  }

  bool isPending() {
    return claim_status == 'Pending Verification';
  }

  bool isApproved() {
    return claim_status == 'Approved';
  }

  bool isRejected() {
    return claim_status == 'Rejected';
  }
}