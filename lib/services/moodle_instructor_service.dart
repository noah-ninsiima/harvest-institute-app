import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/moodle_auth_service.dart'; // Reuse MoodleUserModel if appropriate or create new

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

  /// 1. getCourseParticipants
  Future<List<MoodleUserModel>> getCourseParticipants(
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
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> &&
            (data.containsKey('errorcode') || data.containsKey('exception'))) {
          throw Exception(data['message']);
        }

        if (data is List) {
          return data
              .map((json) =>
                  MoodleUserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch participants');
      }
    } catch (e) {
      debugPrint('Error getting participants: $e');
      rethrow;
    }
  }

  /// 2. getAssignmentSubmissions
  Future<List<MoodleSubmissionModel>> getAssignmentSubmissions(
      String token, int assignmentId) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'mod_assign_get_submissions',
          'moodlewsrestformat': 'json',
          'assignmentids[0]': assignmentId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('assignments')) {
          final assignments = data['assignments'] as List;
          if (assignments.isNotEmpty) {
            final submissions = assignments[0]['submissions'] as List?;
            if (submissions != null) {
              return submissions
                  .map((e) => MoodleSubmissionModel.fromJson(e))
                  .toList();
            }
          }
        }

        return [];
      } else {
        throw Exception('Failed to fetch submissions');
      }
    } catch (e) {
      debugPrint('Error getting submissions: $e');
      rethrow;
    }
  }
}

class MoodleSubmissionModel {
  final int id;
  final int userid;
  final String status;
  final String gradingstatus;

  MoodleSubmissionModel({
    required this.id,
    required this.userid,
    required this.status,
    required this.gradingstatus,
  });

  factory MoodleSubmissionModel.fromJson(Map<String, dynamic> json) {
    return MoodleSubmissionModel(
      id: json['id'] as int,
      userid: json['userid'] as int,
      status: json['status'] as String? ?? 'unknown',
      gradingstatus: json['gradingstatus'] as String? ?? 'unknown',
    );
  }
}
