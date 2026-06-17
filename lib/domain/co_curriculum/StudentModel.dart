import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  // Entity attributes for Student.
  // This model represents student information related to co-curriculum claim.
  final String student_id;
  final String full_name;
  final String student_email;
  final String program_code;
  final String program_name;
  final String Faculty;
  final int current_sem;
  final int co_curriculum_credit;
  final DateTime? date_created;

  const StudentModel({
    required this.student_id,
    required this.full_name,
    required this.student_email,
    required this.program_code,
    required this.program_name,
    required this.Faculty,
    required this.current_sem,
    required this.co_curriculum_credit,
    this.date_created,
  });

  // This factory method converts Firestore document data into StudentModel.
  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StudentModel(
      student_id: data['student_id'] ?? doc.id,
      full_name: data['full_name'] ?? '',
      student_email: data['student_email'] ?? '',
      program_code: data['program_code'] ?? '',
      program_name: data['program_name'] ?? '',
      Faculty: data['Faculty'] ?? '',
      current_sem: data['current_sem'] ?? 0,
      co_curriculum_credit: data['co_curriculum_credit'] ?? 0,
      date_created: convertNullableTimestampToDateTime(
        data['date_created'],
      ),
    );
  }

  // This method converts StudentModel into Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'student_id': student_id,
      'full_name': full_name,
      'student_email': student_email,
      'program_code': program_code,
      'program_name': program_name,
      'Faculty': Faculty,
      'current_sem': current_sem,
      'co_curriculum_credit': co_curriculum_credit,
      'date_created': date_created != null
          ? Timestamp.fromDate(date_created!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  // This method returns updated student credit after claim approval.
  // The system adds 2 co-curriculum credits when Pusat ADAB approves the claim.
  int updateCredit() {
    return co_curriculum_credit + 2;
  }

  // This method checks whether the student already has co-curriculum credit.
  bool hasCoCurriculumCredit() {
    return co_curriculum_credit > 0;
  }

  // This method converts nullable Firestore Timestamp into nullable DateTime.
  static DateTime? convertNullableTimestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return null;
  }
}