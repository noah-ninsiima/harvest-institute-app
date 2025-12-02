import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/moodle_student_service.dart';
import '../../shared/models/moodle_student_models.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../student/providers/student_providers.dart';

class AssignmentRepository {
  final MoodleStudentService _studentService;
  final String _token;
  final int _userId;

  AssignmentRepository({
    required MoodleStudentService studentService,
    required String token,
    required int userId,
  })  : _studentService = studentService,
        _token = token,
        _userId = userId;

  Future<List<StudentAssignment>> getAssignmentsWithStatus(int courseId) async {
    try {
      final assignments = await _studentService.getAssignments(_token, courseId);
      
      final futures = assignments.map((assignment) async {
        try {
          final statusData = await _studentService.getSubmissionStatus(
            _token,
            assignment.id,
            _userId,
          );
          
          String status = 'pending';
          
          if (statusData.containsKey('lastattempt')) {
            final lastAttempt = statusData['lastattempt'];
            if (lastAttempt != null && lastAttempt['submission'] != null) {
               final submissionStatus = lastAttempt['submission']['status'];
               if (submissionStatus == 'submitted') {
                 status = 'submitted';
               } else if (submissionStatus == 'draft') {
                 status = 'draft';
               }
            }
          }
          
          return StudentAssignment(
            assignment: assignment,
            status: status,
          );
        } catch (e) {
          debugPrint('Error fetching status for assignment ${assignment.id}: $e');
          // Fallback to pending if status fetch fails
          return StudentAssignment(
            assignment: assignment,
            status: 'pending',
          );
        }
      });

      return Future.wait(futures);
    } catch (e) {
      debugPrint('Error in getAssignmentsWithStatus: $e');
      rethrow;
    }
  }

  Future<void> submitAssignment(int assignmentId, String url) async {
    await _studentService.saveSubmission(_token, assignmentId, url);
  }
}

class StudentAssignment {
  final MoodleAssignmentModel assignment;
  final String status;

  StudentAssignment({
    required this.assignment,
    required this.status,
  });
  
  bool get isSubmitted => status == 'submitted';
}

final assignmentRepositoryProvider = Provider.family<AssignmentRepository, int>((ref, userId) {
  // Placeholder if we need to access the repository directly later
  throw UnimplementedError('Use studentAssignmentsProvider instead');
});

final studentAssignmentsProvider = FutureProvider.family<List<StudentAssignment>, int>((ref, courseId) async {
  final authService = ref.watch(moodleAuthServiceProvider);
  final studentService = ref.watch(moodleStudentServiceProvider);
  
  final token = await authService.getStoredToken();
  if (token == null) throw Exception('Not authenticated');
  
  final userProfile = await authService.getUserProfile(token);
  
  final repository = AssignmentRepository(
    studentService: studentService,
    token: token,
    userId: userProfile.userid,
  );
  
  return repository.getAssignmentsWithStatus(courseId);
});

