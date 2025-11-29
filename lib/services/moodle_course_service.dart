import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../features/shared/models/moodle_course_model.dart';

class MoodleCourseService {
  final Dio _dio;
  static const String _baseUrl = 'https://lms.rolandsankara.com';

  MoodleCourseService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
            ));

  /// Fetch enrolled courses for a specific user
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
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check for Moodle API error
        if (data is Map<String, dynamic> &&
            (data.containsKey('errorcode') || data.containsKey('exception'))) {
          final errorMessage = data['message'] as String? ??
              data['errorcode'] as String? ??
              'Unknown Moodle error';
          debugPrint('Moodle Course API Error: $errorMessage');
          throw Exception(errorMessage);
        }

        if (data is List) {
          return data
              .map((json) =>
                  MoodleCourseModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // If the response is valid but empty or unexpected format
          debugPrint('Unexpected response format for courses: $data');
          return [];
        }
      } else {
        throw Exception(
            'Failed to fetch courses. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio Error fetching courses: ${e.message}');
      throw Exception('Network error fetching courses: ${e.message}');
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      rethrow;
    }
  }
}

