import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String student_id;
  final String full_name;
  final String student_email;
  final String program_code;
  final String program_name;
  final String Faculty;
  final int current_sem;
  final int co_curriculum_credit;

  StudentModel({
    required this.student_id,
    required this.full_name,
    required this.student_email,
    required this.program_code,
    required this.program_name,
    required this.Faculty,
    required this.current_sem,
    required this.co_curriculum_credit,
  });

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
    );
  }

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
    };
  }

  StudentModel updateCredit() {
    return StudentModel(
      student_id: student_id,
      full_name: full_name,
      student_email: student_email,
      program_code: program_code,
      program_name: program_name,
      Faculty: Faculty,
      current_sem: current_sem,
      co_curriculum_credit: co_curriculum_credit + 2,
    );
  }
}