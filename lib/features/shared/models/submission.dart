import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String submissionId;
  final String assignmentId;
  final String userId;
  final String fileUrl;
  final DateTime submittedAt;
  final String status; // ontime/late
  final double? grade;

  Submission({
    required this.submissionId,
    required this.assignmentId,
    required this.userId,
    required this.fileUrl,
    required this.submittedAt,
    required this.status,
    this.grade,
  });

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'assignmentId': assignmentId,
      'userId': userId,
      'fileUrl': fileUrl,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'grade': grade,
    };
  }

  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      submissionId: map['submissionId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      userId: map['userId'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      status: map['status'] ?? '',
      grade: (map['grade'] as num?)?.toDouble(),
    );
  }
}
