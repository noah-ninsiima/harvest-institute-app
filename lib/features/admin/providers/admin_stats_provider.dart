import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Parallel execution for efficiency
  final results = await Future.wait([
    firestore.collection('courses').count().get(),
    firestore.collection('users').where('role', isEqualTo: 'student').count().get(),
    firestore.collection('users').where('role', isEqualTo: 'instructor').count().get(),
    firestore.collection('payments').get(), // Need to fetch docs to sum amounts
  ]);

  final courseCount = results[0] as AggregateQuerySnapshot;
  final studentCount = results[1] as AggregateQuerySnapshot;
  final instructorCount = results[2] as AggregateQuerySnapshot;
  final paymentsSnapshot = results[3] as QuerySnapshot;

  double totalRevenue = 0.0;
  for (var doc in paymentsSnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle potential type variations (int vs double)
    if (data['amount'] is num) {
      totalRevenue += (data['amount'] as num).toDouble();
    }
  }

  return {
    'totalCourses': courseCount.count ?? 0,
    'activeStudents': studentCount.count ?? 0,
    'instructors': instructorCount.count ?? 0,
    'revenue': totalRevenue,
  };
});
