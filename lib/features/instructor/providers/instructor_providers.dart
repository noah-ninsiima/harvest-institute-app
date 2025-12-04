import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/moodle_instructor_service.dart';
import '../../auth/controllers/auth_controller.dart'; // To access auth state for token
import '../../shared/models/moodle_course_model.dart';

final moodleInstructorServiceProvider = Provider((ref) => MoodleInstructorService());

final instructorCoursesProvider = FutureProvider<List<MoodleCourseModel>>((ref) async {
  final authState = ref.watch(authControllerProvider).value;
  if (authState == null) return [];

  final service = ref.read(moodleInstructorServiceProvider);
  final token = await ref.read(moodleAuthServiceProvider).getStoredToken();
  
  if (token == null) return [];

  return service.getEnrolledCourses(token, authState.userid);
});

final courseEnrolledUsersProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, courseId) async {
  final service = ref.read(moodleInstructorServiceProvider);
  final token = await ref.read(moodleAuthServiceProvider).getStoredToken();
  
  if (token == null) return [];

  return service.getEnrolledUsers(token, courseId);
});

final courseAssignmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, courseId) async {
  final service = ref.read(moodleInstructorServiceProvider);
  final token = await ref.read(moodleAuthServiceProvider).getStoredToken();
  
  if (token == null) return [];

  return service.getAssignments(token, courseId);
});

// Provider to get submissions for a specific assignment
final assignmentSubmissionsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, assignmentId) async {
  final service = ref.read(moodleInstructorServiceProvider);
  final token = await ref.read(moodleAuthServiceProvider).getStoredToken();
  
  if (token == null) return [];

  return service.getSubmissions(token, [assignmentId]);
});
