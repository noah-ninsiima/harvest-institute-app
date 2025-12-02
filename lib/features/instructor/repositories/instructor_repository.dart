import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final instructorRepositoryProvider = Provider((ref) => InstructorRepository());

class InstructorRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  InstructorRepository({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: 'https://lms.rolandsankara.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'moodle_token');
  }

  // Fetch Enrolled Students
  // core_enrol_get_enrolled_users
  Future<List<Map<String, dynamic>>> getEnrolledStudents(int courseId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Moodle token not found');

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

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('exception')) {
           throw Exception(data['message']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching enrolled students: $e');
      rethrow;
    }
  }

  // Get Assignments for a Course (Needed to get Assignment IDs)
  // mod_assign_get_assignments
  Future<List<Map<String, dynamic>>> getAssignments(int courseId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Moodle token not found');

      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_get_assignments',
          'moodlewsrestformat': 'json',
          'courseids[0]': courseId, // Pass course ID
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('courses')) {
          final courses = data['courses'] as List;
          if (courses.isNotEmpty) {
            final assignments = courses[0]['assignments'] as List;
            return List<Map<String, dynamic>>.from(assignments);
          }
        }
        return [];
      } else {
         throw Exception('Failed to fetch assignments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      rethrow;
    }
  }

  // View Submissions
  // mod_assign_get_submissions
  Future<List<Map<String, dynamic>>> getSubmissions(List<int> assignmentIds) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Moodle token not found');

      final Map<String, dynamic> data = {
        'wstoken': token,
        'wsfunction': 'mod_assign_get_submissions',
        'moodlewsrestformat': 'json',
      };

      // Add assignment IDs dynamically
      for (int i = 0; i < assignmentIds.length; i++) {
        data['assignmentids[$i]'] = assignmentIds[i];
      }

      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result is Map && result.containsKey('assignments')) {
          final assignments = result['assignments'] as List;
          // Flatten submissions from all assignments
          List<Map<String, dynamic>> allSubmissions = [];
          for (var assign in assignments) {
            if (assign['submissions'] != null) {
              allSubmissions.addAll(List<Map<String, dynamic>>.from(assign['submissions']));
            }
          }
          return allSubmissions;
        } else if (result is Map && result.containsKey('exception')) {
            throw Exception(result['message']);
        }
        return [];
      } else {
        throw Exception('Failed to fetch submissions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
      rethrow;
    }
  }
}

