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
}

