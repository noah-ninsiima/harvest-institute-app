import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Only for debug printing

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDatabase() async {
    debugPrint('Starting database seeding...');

    try {
      // --- Sample Data Definitions ---
      const String studentUserId = 'user_student_1';
      const String instructorUserId = 'user_instructor_1';
      const String courseId = 'course_flutter_101';
      const String enrollmentId = '${studentUserId}_$courseId'; // Composite ID

      // 1. Users Collection
      await _firestore.collection('users').doc(studentUserId).set({
        'full_name': 'Jane Doe',
        'email': 'student@harvest.com',
        'contact': '+1123456789',
        'role': 'student',
      }, SetOptions(merge: true));
      debugPrint('Student User seeded: $studentUserId');

      await _firestore.collection('users').doc(instructorUserId).set({
        'full_name': 'Dr. Alex Instructor',
        'email': 'instructor@harvest.com',
        'contact': '+1987654321',
        'role': 'instructor',
      }, SetOptions(merge: true));
      debugPrint('Instructor User seeded: $instructorUserId');


      // 2. Courses Collection
      await _firestore.collection('courses').doc(courseId).set({
        'name': 'Flutter Development',
        'tuition': 500000.0,
        'duration': 12,
        'instructor_id': instructorUserId,
      }, SetOptions(merge: true));
      debugPrint('Course seeded: $courseId');

      // 3. Enrollments Collection (Crucial: Composite ID)
      await _firestore.collection('enrollments').doc(enrollmentId).set({
        'user_id': studentUserId,
        'course_id': courseId,
        'status': 'active',
        'payment_status': 'pending',
        'enrol_date': Timestamp.now(),
      }, SetOptions(merge: true));
      debugPrint('Enrollment seeded: $enrollmentId');

      // 4. Payments Collection
      await _firestore.collection('payments').add({
        'amount': 500000.0,
        'enrol_id': enrollmentId,
        'date': Timestamp.now(),
        'reason': 'Course enrollment payment for $courseId',
        'payment_method': 'External Link'
      });
      debugPrint('Payment record added for enrollment: $enrollmentId');

      // Assignment for course_flutter_101
      const String assignmentId = 'assignment_flutter_intro';
      await _firestore.collection('assignments').doc(assignmentId).set({
        'course_id': courseId,
        'due_date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'description': 'Complete the "Hello World" Flutter app and deploy it.',
      }, SetOptions(merge: true));
      debugPrint('Assignment seeded: $assignmentId');

      // Initial submission (ungraded) for the student for this assignment
      await _firestore.collection('submissions').add({
        'assignment_id': assignmentId,
        'user_id': studentUserId,
        'submission_url': 'https://github.com/janedoe/flutter_hello_world',
        'submission_date': Timestamp.now(),
        'status': 'submitted',
      });
      debugPrint('Sample Submission added.');

      debugPrint('Database seeding completed successfully!');
    } catch (e) {
      debugPrint('Error during database seeding: $e');
    }
  }
}
