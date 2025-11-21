import 'package:cloud_firestore/cloud_firestore.dart';

class Enrollment {
  final String enrolId;
  final String userId;
  final String courseId;
  final DateTime enrolDate;
  final String status;

  Enrollment({
    required this.enrolId,
    required this.userId,
    required this.courseId,
    required this.enrolDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'enrolId': enrolId,
      'userId': userId,
      'courseId': courseId,
      'enrolDate': Timestamp.fromDate(enrolDate),
      'status': status,
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      enrolId: map['enrolId'] ?? '',
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      enrolDate: (map['enrolDate'] as Timestamp).toDate(),
      status: map['status'] ?? '',
    );
  }
}
