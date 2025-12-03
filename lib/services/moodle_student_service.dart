import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../features/shared/models/moodle_course_model.dart';
import '../features/shared/models/moodle_student_models.dart';
import '../models/moodle_grade_model.dart'; // Add import for MoodleGradeModel and MoodleUserGrade

class MoodleStudentService {
  final Dio _dio;
  static const String _baseUrl = 'https://lms.rolandsankara.com';

  MoodleStudentService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
            ));

  // Helper to handle Moodle API response
  dynamic _handleResponse(Response response) {
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> &&
          (data.containsKey('errorcode') || data.containsKey('exception'))) {
        final errorMessage = data['message'] as String? ??
            data['errorcode'] as String? ??
            'Unknown Moodle error';
        throw Exception(errorMessage);
      }
      return data;
    } else {
      throw Exception(
          'Request failed with status code: ${response.statusCode}');
    }
  }

  Future<List<MoodleCourseModel>> getEnrolledCourses(
      String token, int userId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'core_enrol_get_users_courses',
          'moodlewsrestformat': 'json',
          'userid': userId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = _handleResponse(response);

      if (data is List) {
        return data
            .map((json) =>
                MoodleCourseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      rethrow;
    }
  }

  Future<List<MoodleAssignmentModel>> getAssignments(
      String token, int courseId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_get_assignments',
          'moodlewsrestformat': 'json',
          'courseids[0]': courseId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = _handleResponse(response);

      // mod_assign_get_assignments returns { courses: [ { assignments: [...] } ] }
      if (data is Map<String, dynamic> && data.containsKey('courses')) {
        final courses = data['courses'] as List;
        if (courses.isNotEmpty) {
          final assignments = courses[0]['assignments'] as List;
          return assignments
              .map((json) =>
                  MoodleAssignmentModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      rethrow;
    }
  }

  Future<List<MoodleUserGrade>> getGrades(
      String token, int courseId, int userId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'gradereport_user_get_grade_items',
          'moodlewsrestformat': 'json',
          'courseid': courseId,
          'userid': userId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data.containsKey('usergrades')) {
        final userGrades = data['usergrades'] as List;
        return userGrades
            .map((json) =>
                MoodleUserGrade.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching grades: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourseCompletionStatus(
      String token, int courseId, int userId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'core_completion_get_course_completion_status',
          'moodlewsrestformat': 'json',
          'courseid': courseId,
          'userid': userId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      // If no completion tracking is enabled, this might return a specific warning or empty structure
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error fetching course completion status: $e');
      // Return empty map or null rather than crashing if completion isn't enabled for a course
      return {};
    }
  }

  Future<Map<String, dynamic>> getSubmissionStatus(
      String token, int assignId, int userId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_get_submission_status',
          'moodlewsrestformat': 'json',
          'assignid': assignId,
          'userid': userId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error fetching submission status: $e');
      rethrow;
    }
  }

  Future<void> saveSubmission(
      String token, int assignId, String onlineText) async {
    try {
      debugPrint('Saving submission for assignment $assignId: $onlineText');
      
      // Real implementation for Moodle 'mod_assign_save_submission'
      // This function creates/updates a DRAFT submission.
      // To finalize, you usually need 'mod_assign_submit_for_grading' (if enabled), 
      // but often 'save_submission' with plugindata is enough for "Submitted for grading" depending on settings.
      
      // For onlinetext plugin:
      // plugindata[onlinetext_editor][text]
      // plugindata[onlinetext_editor][format] = 1 (HTML)
      // plugindata[onlinetext_editor][itemid] is technically required but Moodle often generates one if 0.
      
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_save_submission',
          'moodlewsrestformat': 'json',
          'assignmentid': assignId,
          'plugindata[onlinetext_editor][text]': onlineText,
          'plugindata[onlinetext_editor][format]': 1, 
          'plugindata[onlinetext_editor][itemid]': 0, // Start new draft
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      final data = _handleResponse(response);
      debugPrint('Save submission response: $data');
      
      // Check for specific warnings (like 'Draft saved')
      if (data is List && data.isNotEmpty) {
          // Sometimes returns list of warnings
           debugPrint('Submission warnings: $data');
      }
      
      // OPTIONAL: If Moodle requires a separate "Submit for grading" step (locking the submission),
      // we would call 'mod_assign_submit_for_grading' here.
      // For now, we assume 'save_submission' puts it in the Draft or Submitted state depending on assignment settings.
      // Many simple assignments don't require the separate locking step.
      
      // If the user gets "Draft" status in UI but wants "Submitted", we might need the extra call.
      // Let's attempt to Submit For Grading as well to be sure, if the assignment allows it.
      
      try {
         await _submitForGrading(token, assignId);
      } catch (e) {
        // This might fail if the assignment doesn't require/allow explicit submission (e.g. just saving is enough)
        // or if there is no submission statement to accept.
        debugPrint('Submit for grading skipped or failed (might be optional): $e');
      }

    } catch (e) {
      debugPrint('Error saving submission: $e');
      rethrow;
    }
  }
  
  Future<void> _submitForGrading(String token, int assignId) async {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_submit_for_grading',
          'moodlewsrestformat': 'json',
          'assignmentid': assignId,
          'acceptsubmissionstatement': 1, // Often required
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      _handleResponse(response);
  }
}
