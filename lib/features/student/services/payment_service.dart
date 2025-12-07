import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart'; // Import for ClientException

import '../../shared/models/course.dart';
import '../../shared/models/enrollment.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/moodle_course_service.dart';
import '../../../services/moodle_auth_service.dart';

final paymentServiceProvider = Provider((ref) {
  final moodleAuthService = ref.watch(moodleAuthServiceProvider);
  final moodleCourseService = MoodleCourseService();
  return PaymentService(moodleAuthService, moodleCourseService);
});

class PaymentService {
  final MoodleAuthService _moodleAuthService;
  final MoodleCourseService _moodleCourseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PaymentService(this._moodleAuthService, this._moodleCourseService);

  // Stream of payment history for a user
  Stream<List<PaymentModel>> getPaymentHistory(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    });
  }

  // Calculate outstanding balance
  Future<double> getOutstandingBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final totalTuition = (userDoc.data()?['tuitionTotal'] ?? 0.0).toDouble();

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

  Future<void> makePayment({
    required BuildContext context,
    required Course course,
    required UserModel user,
  }) async {
    try {
      final String txRef = "harvest-${const Uuid().v4()}";
      final String amount = course.tuition.toString();

      // 1. Initialize Flutterwave
      final Customer customer = Customer(
        name: user.fullName,
        phoneNumber: user.contact, // Use contact or empty
        email: user.email,
      );

      final Flutterwave flutterwave = Flutterwave(
        publicKey: "FLWPUBK_TEST-3818d4ff3308d1d785211b81216c1949-X",
        currency: "UGX",
        redirectUrl:
            "https://harvest-institute.com/payment-redirect", // Optional/Dummy
        txRef: txRef,
        amount: amount,
        customer: customer,
        paymentOptions: "card, mobilemoneyuganda", // standard options
        customization: Customization(
          title: "Harvest Institute",
          description: "Tuition Payment for ${course.name}",
          logo: "https://harvest-institute.com/logo.png", // Optional
        ),
        isTestMode: true,
      );

      // 2. Charge
      final ChargeResponse response = await flutterwave.charge(context);

      // 3. Handle Response
      if (response.success == true && response.status == "successful") {
        debugPrint("Payment Successful: ${response.transactionId}");

        await _handleSuccessfulPayment(course, user, amount, txRef);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Successful! Enrolling...")),
          );
        }
      } else {
        // Payment failed or cancelled
        debugPrint("Payment Failed/Cancelled: ${response.status}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Failed: ${response.status}")),
          );
        }
      }
    } catch (e) {
      debugPrint("Payment Error: $e");

      String errorMessage = "An error occurred: $e";

      // Specialized error handling for Web CORS issues
      if (e.toString().contains("ClientException") ||
          e.toString().contains("XMLHttpRequest")) {
        errorMessage =
            "Web Security Error: Your browser blocked the payment. Please test this feature on an Android Emulator or a real phone.";
      }
      // Also catch explicit ClientException if we can verify the type at runtime,
      // but string check is robust for different platforms.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }
  }

  Future<void> _handleSuccessfulPayment(
      Course course, UserModel user, String amount, String txRef) async {
    try {
      // 1. Moodle Sync
      // We need the user's token.
      // Assuming the user is logged in to Moodle via AuthController logic.
      final token = await _moodleAuthService.getStoredToken();

      if (token != null) {
        // Parse courseId to int for Moodle
        final moodleCourseId = int.tryParse(course.courseId) ?? 0;
        if (moodleCourseId > 0) {
          await _moodleCourseService.enrolUser(token, moodleCourseId);
        } else {
          debugPrint(
              "Invalid Moodle Course ID: ${course.courseId}. Skipping Moodle enrollment.");
        }
      } else {
        debugPrint("No Moodle token found. Skipping Moodle enrollment.");
      }

      // 2. Firestore Payment Record
      final paymentRef = _firestore.collection('payments').doc();
      await paymentRef.set({
        'paymentId': paymentRef.id,
        'userId': user.uid,
        'studentId': user.uid, // As requested
        'courseId': course.courseId,
        'amount': double.tryParse(amount) ?? 0.0,
        'txRef': txRef,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'date': Timestamp.now(), // Keep compatibility with getPaymentHistory
        'reason': 'course_enrollment',
        'paymentMethod': 'Flutterwave',
      });

      // 3. Unlock App (Create Enrollment)
      final enrollmentRef = _firestore.collection('enrollments').doc();
      // Check if already exists to avoid duplicates?
      // We'll just create a new one as per instructions "Create a document".

      final newEnrollment = Enrollment(
        enrolId: enrollmentRef.id,
        userId: user.uid,
        courseId: course.courseId,
        enrolDate: DateTime.now(),
        status: 'active',
      );

      await enrollmentRef.set(newEnrollment.toMap());

      // Update course student list (optional but good practice)
      await _firestore.collection('courses').doc(course.courseId).update({
        'studentIds': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      debugPrint("Error in fulfillment logic: $e");
      // Consider retrying or logging to a queue if critical
      rethrow;
    }
  }

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

  // Deprecated method for backward compatibility if needed, calling new logic if possible
  Future<bool> processEnrollment({
    required String userId,
    required String courseId,
    required double amount,
    required String paymentMethod,
  }) async {
    // This was the old mock method.
    // We can't easily redirect to makePayment because it needs Context and Models.
    // So we leave it or deprecated it.
    debugPrint("processEnrollment is deprecated. Use makePayment.");
    return false;
  }
}
