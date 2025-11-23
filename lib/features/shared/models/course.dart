import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String courseId;
  final String name;
  final String duration;
  final double tuition;
  final String instructorId;
  final DateTime createdAt;
  final String schoolCategory; 

  Course({
    required this.courseId,
    required this.name,
    required this.duration,
    required this.tuition,
    required this.instructorId,
    required this.createdAt,
    required this.schoolCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': name,
      'duration': duration,
      'tuition': tuition,
      'instructorId': instructorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'schoolCategory': schoolCategory,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      courseId: map['courseId'] ?? '',
      name: map['name'] ?? '',
      duration: map['duration'] ?? '',
      tuition: (map['tuition'] ?? 0.0).toDouble(),
      instructorId: map['instructorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      schoolCategory: map['schoolCategory'] ?? 'Leadership & Ministry', // Default
    );
  }
}
