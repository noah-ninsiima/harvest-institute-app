import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/models/enrollment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock payment processing and enrollment creation
  Future<bool> processEnrollment({
    required String userId,
    required String courseId,
    required double amount,
    required String paymentMethod, // 'Card' or 'Mobile Money'
  }) async {
    try {
      // 1. Validation: Check if already enrolled
      final existingEnrollment = await _firestore
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        throw Exception("User is already enrolled in this course.");
      }

      // 2. Create Payment Record
      final paymentRef = _firestore.collection('payments').doc();
      await paymentRef.set({
        'paymentId': paymentRef.id,
        'userId': userId,
        'courseId': courseId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'date': Timestamp.now(),
        'reason': 'course_enrollment',
        'status': 'completed', // Mock success
      });

      // 3. Create Enrollment Record
      final enrollmentRef = _firestore.collection('enrollments').doc();
      final newEnrollment = Enrollment(
        enrolId: enrollmentRef.id,
        userId: userId,
        courseId: courseId,
        enrolDate: DateTime.now(),
        status: 'active',
      );

      await enrollmentRef.set(newEnrollment.toMap());
      
      // Optional: Add studentId to the course document if needed for instructor queries
       await _firestore.collection('courses').doc(courseId).update({
         'studentIds': FieldValue.arrayUnion([userId]),
       });

      return true;
    } catch (e) {
      debugPrint("Enrollment Error: $e");
      rethrow;
    }
  }
}
