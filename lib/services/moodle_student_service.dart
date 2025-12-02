import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../features/shared/models/moodle_course_model.dart';
import '../features/shared/models/moodle_student_models.dart';

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

  Future<List<MoodleGradeModel>> getGrades(
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

      // gradereport_user_get_grade_items returns { usergrades: [ { gradeitems: [...] } ] }
      if (data is Map<String, dynamic> && data.containsKey('usergrades')) {
        final userGrades = data['usergrades'] as List;
        if (userGrades.isNotEmpty) {
          final gradeItems = userGrades[0]['gradeitems'] as List;
          return gradeItems
              .map((json) =>
                  MoodleGradeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching grades: $e');
      rethrow;
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
      // Note: plugindata needs to be structured correctly for the specific plugin (onlinetext)
      // This is a simplified example assuming standard 'onlinetext_editor' structure.
      // Moodle API often requires nested array/object structures that are tricky with simple maps in Dio.
      // We might need to use standard URL encoding or a specific structure.

      // For 'onlinetext' plugin:
      // plugindata[onlinetext_editor][text] = ...
      // plugindata[onlinetext_editor][format] = 1
      // plugindata[onlinetext_editor][itemid] = ... (usually handled by moodle if new)

      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_save_submission',
          'moodlewsrestformat': 'json',
          'assignmentid': assignId,
          'plugindata[onlinetext_editor][text]': onlineText,
          'plugindata[onlinetext_editor][format]': 1, // HTML format
          // 'plugindata[files_filemanager]': 0, // If we handled files
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      _handleResponse(response);

      // Optionally call mod_assign_submit_for_grading if required by the assignment configuration
      // But often save_submission is enough for draft or direct submission depending on settings.
    } catch (e) {
      debugPrint('Error saving submission: $e');
      rethrow;
    }
  }
}
