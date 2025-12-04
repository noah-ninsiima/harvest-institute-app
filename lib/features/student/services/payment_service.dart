import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/enrollment.dart';
import '../../shared/models/payment_model.dart';

final paymentServiceProvider = Provider((ref) => PaymentService());

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of payment history for a user
  Stream<List<PaymentModel>> getPaymentHistory(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
    });
  }

  // Calculate outstanding balance
  // In a real app, this might fetch a pre-calculated field or sum "due" records.
  // Here we'll assume a standard tuition fee and subtract paid amounts.
  Future<double> getOutstandingBalance(String userId) async {
    try {
       // Example: Fetch from user profile if stored there, or calculate
       // Let's assume a 'tuition' collection or field on user
       // For this demo, we'll assume a fixed Total Tuition or fetch it.
       
       // 1. Get total tuition fee (Mocked or from User profile)
       // double totalTuition = 2000000; // Example: 2 Million UGX
       
       // Better: Fetch 'tuitionTotal' from user doc, default to 0 if not set
       final userDoc = await _firestore.collection('users').doc(userId).get();
       final totalTuition = (userDoc.data()?['tuitionTotal'] ?? 0.0).toDouble();

       // 2. Sum up all completed payments
       final paymentsSnapshot = await _firestore
           .collection('payments')
           .where('userId', isEqualTo: userId)
           .where('status', isEqualTo: 'completed')
           .get();

       double totalPaid = 0.0;
       for (var doc in paymentsSnapshot.docs) {
         totalPaid += (doc.data()['amount'] ?? 0.0).toDouble();
       }

       return totalTuition - totalPaid;
    } catch (e) {
      debugPrint("Error fetching balance: $e");
      return 0.0;
    }
  }

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
  
  // New: Record a general tuition payment (not linked to specific course enrollment)
  Future<void> recordPayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    required String txRef,
  }) async {
    final paymentRef = _firestore.collection('payments').doc();
      await paymentRef.set({
        'paymentId': paymentRef.id,
        'userId': userId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'date': Timestamp.now(),
        'reason': 'tuition',
        'status': 'completed',
        'txRef': txRef,
      });
  }
}
