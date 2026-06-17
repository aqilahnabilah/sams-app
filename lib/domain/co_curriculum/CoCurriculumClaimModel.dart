import 'package:cloud_firestore/cloud_firestore.dart';

class CoCurriculumClaimModel {
  // Entity attributes for CoCurriculumClaim.
  // This model represents a student's co-curriculum credit claim record.
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

  const CoCurriculumClaimModel({
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

  // This factory method converts Firestore document data into CoCurriculumClaimModel.
  factory CoCurriculumClaimModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CoCurriculumClaimModel(
      claim_id: data['claim_id'] ?? doc.id,
      student_id: data['student_id'] ?? '',
      completed_module_count: data['completed_module_count'] ?? 0,
      claim_status: data['claim_status'] ?? 'Pending Verification',
      submission_date: convertTimestampToDateTime(
        data['submission_date'],
      ),
      verified_by: data['verified_by'],
      verification_date: convertNullableTimestampToDateTime(
        data['verification_date'],
      ),
      rejection_reason: data['rejection_reason'],
      credit_awarded: data['credit_awarded'] ?? 2,
      date_created: convertNullableTimestampToDateTime(
        data['date_created'],
      ),
    );
  }

  // This method converts CoCurriculumClaimModel into Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'claim_id': claim_id,
      'student_id': student_id,
      'completed_module_count': completed_module_count,
      'claim_status': claim_status,
      'submission_date': Timestamp.fromDate(submission_date),
      'verified_by': verified_by,
      'verification_date': verification_date != null
          ? Timestamp.fromDate(verification_date!)
          : null,
      'rejection_reason': rejection_reason,
      'credit_awarded': credit_awarded,
      'date_created': date_created != null
          ? Timestamp.fromDate(date_created!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // This method checks whether the claim is still pending verification.
  bool isPending() {
    return claim_status == 'Pending Verification';
  }

  // This method checks whether the claim has been approved.
  bool isApproved() {
    return claim_status == 'Approved';
  }

  // This method checks whether the claim has been rejected.
  bool isRejected() {
    return claim_status == 'Rejected';
  }

  // This method converts required Firestore Timestamp into DateTime.
  static DateTime convertTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return DateTime.now();
  }

  // This method converts nullable Firestore Timestamp into nullable DateTime.
  static DateTime? convertNullableTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }
}