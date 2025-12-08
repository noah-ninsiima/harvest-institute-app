import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markAttendance({
    required String studentId,
    required String studentName,
    required dynamic courseId, // Can be int (ID) or String (Shortname)
    required String date,
  }) async {
    try {
      final query = await _firestore
          .collection('attendance')
          .where('student_id', isEqualTo: studentId)
          .where('course_id', isEqualTo: courseId)
          .where('date', isEqualTo: date)
          .get();

      if (query.docs.isNotEmpty) {
        throw Exception('Attendance already marked for today.');
      }

      await _firestore.collection('attendance').add({
        'student_id': studentId,
        'student_name': studentName,
        'course_id': courseId,
        'date': date,
        'status': 'present',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// Real-time stream of attendance for a specific course and date.
  /// [courseShortName] matches the QR code data (e.g., 'BAT01').
  /// [date] format: "yyyy-MM-dd"
  Stream<List<Map<String, dynamic>>> getCourseAttendanceStream(String courseShortName, String date) {
    return _firestore
        .collection('attendance')
        .where('course_id', isEqualTo: courseShortName) // Matches 'BAT01'
        .where('date', isEqualTo: date)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

