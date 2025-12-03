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
  final userProfile = await authService.getUserProfile(token);

  final courses = await studentService.getEnrolledCourses(token, userProfile.userid);

  // Enhanced: Fetch accurate progress for each course separately if needed
  // Note: core_enrol_get_users_courses often returns 'progress' but it might be null depending on Moodle settings.
  // If we find progress is missing or we want to be sure, we can fetch it explicitly.
  
  // Let's try to populate progress if it's missing or just override it to be sure with the dedicated API.
  // Since getCourseCompletion is lightweight, we can do it in parallel.
  
  final coursesWithProgress = await Future.wait(courses.map((course) async {
    // If course.progress is already valid, we might skip, but user reported it missing/not working.
    // So let's fetch it.
    try {
      final completion = await studentService.getCourseCompletion(token, course.id, userProfile.userid);
      // Return new model with updated progress
      return MoodleCourseModel(
        id: course.id,
        fullname: course.fullname,
        shortname: course.shortname,
        progress: completion, // Use fetched completion
        category: course.category,
        startDate: course.startDate,
        endDate: course.endDate,
        imageUrl: course.imageUrl,
      );
    } catch (e) {
      // Fallback to existing data
      return course;
    }
  }));

  return coursesWithProgress;
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

