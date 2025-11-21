import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String assignmentId;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueDate;
  final double maxPoints;

  Assignment({
    required this.assignmentId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'courseId': courseId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'maxPoints': maxPoints,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      assignmentId: map['assignmentId'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      maxPoints: (map['maxPoints'] ?? 0.0).toDouble(),
    );
  }
}
