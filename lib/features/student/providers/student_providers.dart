import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/moodle_student_service.dart';
import '../../shared/models/moodle_course_model.dart';
import '../../shared/models/moodle_student_models.dart' hide MoodleGradeModel;
import '../../../models/moodle_grade_model.dart'; // Import new model
import '../../auth/controllers/auth_controller.dart'; // For moodleAuthServiceProvider

// Provider for MoodleStudentService
final moodleStudentServiceProvider = Provider((ref) => MoodleStudentService());

// Provider for Enrolled Courses
final enrolledCoursesProvider = FutureProvider<List<MoodleCourseModel>>((ref) async {
  final authService = ref.watch(moodleAuthServiceProvider);
  final studentService = ref.watch(moodleStudentServiceProvider);

  final token = await authService.getStoredToken();
  if (token == null) throw Exception('Not authenticated');

  // We need userId. 
  // Optimization: We should cache the user profile in a StateProvider to avoid refetching.
  // But for now, re-fetching to be safe as per previous pattern.
  final userProfile = await authService.getUserProfile(token);

  return studentService.getEnrolledCourses(token, userProfile.userid);
});

// Family Provider for Assignments (param: courseId)
final courseAssignmentsProvider = FutureProvider.family<List<MoodleAssignmentModel>, int>((ref, courseId) async {
  final authService = ref.watch(moodleAuthServiceProvider);
  final studentService = ref.watch(moodleStudentServiceProvider);

  final token = await authService.getStoredToken();
  if (token == null) throw Exception('Not authenticated');

  return studentService.getAssignments(token, courseId);
});

// Family Provider for Grades (param: courseId)
final courseGradesProvider = FutureProvider.family<List<MoodleGradeModel>, int>((ref, courseId) async {
  final authService = ref.watch(moodleAuthServiceProvider);
  final studentService = ref.watch(moodleStudentServiceProvider);

  final token = await authService.getStoredToken();
  if (token == null) throw Exception('Not authenticated');

  final userProfile = await authService.getUserProfile(token);

  // getGrades now returns List<MoodleUserGrade>
  final userGrades = await studentService.getGrades(token, courseId, userProfile.userid);
  
  if (userGrades.isNotEmpty) {
    return userGrades.first.gradeItems;
  }
  return [];
});

