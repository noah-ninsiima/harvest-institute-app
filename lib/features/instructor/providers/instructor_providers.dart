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

