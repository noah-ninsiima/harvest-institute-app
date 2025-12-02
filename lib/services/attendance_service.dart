import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Marks attendance for a student in a specific course session.
  ///
  /// [qrData] format: "courseId:validDate" (e.g., "101:2025-11-28")
  /// [userId] is the UID of the student.
  Future<void> markAttendance(String qrData, String userId) async {
    try {
      // 1. Parse QR Data
      final parts = qrData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid QR Code Format. Expected "courseId:date".');
      }

      final courseId = parts[0].trim();
      final date = parts[1].trim();

      if (courseId.isEmpty || date.isEmpty) {
        throw Exception('Invalid QR Code Data (Empty fields).');
      }

      // 2. Validate: Check for Duplicate
      // Query for existing attendance record for this user, course, and date
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('user_id', isEqualTo: userId)
          .where('course_id', isEqualTo: courseId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Attendance already marked for this session.');
      }

      // 3. Write: Create new attendance record
      await _firestore.collection('attendance').add({
        'user_id': userId,
        'course_id': courseId,
        'date': date, // Storing the session date explicitly
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'present',
        'device_id': '', // Placeholder for now
      });

      debugPrint('Attendance marked successfully for user $userId in course $courseId on $date');
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      rethrow; // Propagate error to UI
    }
  }
}

