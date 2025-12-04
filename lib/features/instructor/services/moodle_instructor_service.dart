import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/moodle_course_model.dart';

class MoodleInstructorService {
  final Dio _dio;
  static const String _baseUrl = 'https://lms.rolandsankara.com';

  MoodleInstructorService({Dio? dio})
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

  /// Get courses where the user is enrolled (as teacher or otherwise)
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
            .map((json) => MoodleCourseModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      rethrow;
    }
  }

  /// Get participants in a course
  Future<List<Map<String, dynamic>>> getEnrolledUsers(
      String token, int courseId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'core_enrol_get_enrolled_users',
          'moodlewsrestformat': 'json',
          'courseid': courseId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = _handleResponse(response);

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching enrolled users for course $courseId: $e');
      // Some Moodle configurations restrict this call, so we might return empty if failed
      // But usually rethrow is better for debugging.
      // For UI resilience, we might want to return empty list if permission denied.
      if (e.toString().contains('Access control exception') || e.toString().contains('capabilities')) {
          return [];
      }
      rethrow;
    }
  }

  /// Get assignments for a course
  Future<List<Map<String, dynamic>>> getAssignments(
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

      if (data is Map<String, dynamic> && data.containsKey('courses')) {
        final courses = data['courses'] as List;
        if (courses.isNotEmpty) {
          final courseData = courses.first;
          if (courseData['assignments'] != null) {
             return List<Map<String, dynamic>>.from(courseData['assignments']);
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching assignments for course $courseId: $e');
      rethrow;
    }
  }

  /// Get submissions for specific assignments
  Future<List<Map<String, dynamic>>> getSubmissions(
      String token, List<int> assignmentIds) async {
    if (assignmentIds.isEmpty) return [];

    try {
      // Construct map for assignment ids
      final Map<String, dynamic> requestData = {
        'wstoken': token,
        'wsfunction': 'mod_assign_get_submissions',
        'moodlewsrestformat': 'json',
      };

      for (int i = 0; i < assignmentIds.length; i++) {
        requestData['assignmentids[$i]'] = assignmentIds[i];
      }

      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: requestData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data.containsKey('assignments')) {
         final assignments = data['assignments'] as List;
         // Flatten submissions from all assignments
         List<Map<String, dynamic>> allSubmissions = [];
         for (var assign in assignments) {
            if (assign['submissions'] != null) {
              allSubmissions.addAll(List<Map<String, dynamic>>.from(assign['submissions']));
            }
         }
         return allSubmissions;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
      rethrow;
    }
  }
}

