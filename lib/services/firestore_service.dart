import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markAttendance({
    required String studentId,
    required String studentName,
    required int courseId,
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
}

