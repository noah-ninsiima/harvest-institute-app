import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // --- Stream all courses ---
  Stream<List<Map<String, dynamic>>> getCourses() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // --- Get student's enrollments ---
  Stream<List<Map<String, dynamic>>> getStudentEnrollments(String userId) {
    return _firestore
        .collection('enrollments')
        .where('user_id', isEqualTo: userId) // Corrected syntax
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // --- Enroll student in a course ---
  Future<void> enrollInCourse(String courseId) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }
    final String userId = currentUser.uid;
    final String enrollmentId = '${userId}_$courseId'; // Composite ID

    try {
      // Check if already enrolled (though UI should prevent this, it's a double check)
      final existingEnrollment = await _firestore.collection('enrollments').doc(enrollmentId).get();
      if (existingEnrollment.exists) {
        throw Exception('You are already enrolled in this course.');
      }

      await _firestore.collection('enrollments').doc(enrollmentId).set({
        'user_id': userId,
        'course_id': courseId,
        'enrol_date': FieldValue.serverTimestamp(),
        'status': 'active', // Default enrollment status
        'payment_status': 'pending', // Default payment status
      });
      debugPrint('User $userId enrolled in course $courseId with ID $enrollmentId.');
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error enrolling in course: ${e.code} - ${e.message}');
      // Rethrow for UI to handle specifically
      throw Exception('Failed to enroll: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('General Error enrolling in course: $e');
      throw Exception('An unexpected error occurred during enrollment.');
    }
  }
}
