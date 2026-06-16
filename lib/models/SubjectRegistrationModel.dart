import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectRegistrationModel {
  final String id;
  final String studentEmail;
  final String studentName;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String labSectionName;
  final List<Map<String, dynamic>> lectures;
  final List<Map<String, dynamic>> labs;
  final String status;
  final String examDate;
  final String examTime;
  final int creditHour;
  final DateTime? createdAt;

  SubjectRegistrationModel({
    required this.id,
    required this.studentEmail,
    required this.studentName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.sectionName,
    required this.labSectionName,
    required this.lectures,
    required this.labs,
    required this.status,
    required this.examDate,
    required this.examTime,
    required this.creditHour,
    this.createdAt,
  });

  // Factory constructor to parse document from Firestore snapshot
  factory SubjectRegistrationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse lectures array safely
    final List<dynamic> rawLectures = data['lectures'] ?? [];
    final List<Map<String, dynamic>> parsedLectures = rawLectures.map((lec) {
      return Map<String, dynamic>.from(lec as Map);
    }).toList();

    // Parse labs array safely
    final List<dynamic> rawLabs = data['labs'] ?? [];
    final List<Map<String, dynamic>> parsedLabs = rawLabs.map((lab) {
      return Map<String, dynamic>.from(lab as Map);
    }).toList();

    // Parse createdAt timestamp safely
    DateTime? parsedCreatedAt;
    if (data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    }

    return SubjectRegistrationModel(
      id: doc.id,
      studentEmail: data['studentEmail'] ?? '',
      studentName: data['studentName'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectCode: data['subjectCode'] ?? '',
      subjectName: data['subjectName'] ?? '',
      sectionName: data['sectionName'] ?? '',
      labSectionName: data['labSectionName'] ?? '',
      lectures: parsedLectures,
      labs: parsedLabs,
      status: data['status'] ?? 'pending',
      examDate: data['examDate'] ?? '',
      examTime: data['examTime'] ?? '',
      creditHour: data['creditHour'] ?? 0,
      createdAt: parsedCreatedAt,
    );
  }

  // Convert model instance to map format for Firestore submission
  Map<String, dynamic> toMap() {
    return {
      'studentEmail': studentEmail,
      'studentName': studentName,
      'subjectId': subjectId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'sectionName': sectionName,
      'labSectionName': labSectionName,
      'lectures': lectures,
      'labs': labs,
      'status': status,
      'examDate': examDate,
      'examTime': examTime,
      'creditHour': creditHour,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
