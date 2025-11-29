import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Base URL for Moodle LMS
const String _baseUrl = 'https://lms.rolandsankara.com';
const String _serviceName = 'moodle_mobile_app';

/// Model representing a Moodle user profile
class MoodleUserModel {
  final int userid;
  final String firstname;
  final String lastname;
  final String? userpictureurl;
  final String email;
  final String username;

  MoodleUserModel({
    required this.userid,
    required this.firstname,
    required this.lastname,
    this.userpictureurl,
    required this.email,
    required this.username,
  });

  String get fullName => '$firstname $lastname';

  factory MoodleUserModel.fromJson(Map<String, dynamic> json) {
    return MoodleUserModel(
      userid: json['userid'] as int,
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      userpictureurl: json['userpictureurl'] as String?,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'firstname': firstname,
      'lastname': lastname,
      'userpictureurl': userpictureurl,
      'email': email,
      'username': username,
    };
  }
}

/// Service for Moodle authentication using token-based authentication
class MoodleAuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  MoodleAuthService({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ?? Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Login with username and password
  Future<String> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/login/token.php',
        data: {
          'username': username,
          'password': password,
          'service': _serviceName,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('error')) {
          final errorMessage = data['error'] as String? ?? 'Unknown error occurred';
          debugPrint('Moodle login error: $errorMessage');
          throw Exception(errorMessage);
        }

        if (data is Map<String, dynamic> && data.containsKey('token')) {
          final token = data['token'] as String;
          await _secureStorage.write(key: 'moodle_token', value: token);
          debugPrint('Moodle login successful, token saved');
          return token;
        } else {
          throw Exception('Token not found in response');
        }
      } else {
        throw Exception('Login failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio error during Moodle login: ${e.message}');
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('error')) {
          throw Exception(errorData['error'] as String);
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Error during Moodle login: $e');
      rethrow;
    }
  }

  /// Get user profile information using the authentication token
  Future<MoodleUserModel> getUserProfile(String token) async {
    try {
      final response = await _dio.post(
        '/webservice/rest/server.php',
        data: {
          'wstoken': token,
          'wsfunction': 'core_webservice_get_site_info',
          'moodlewsrestformat': 'json',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('errorcode') || data.containsKey('exception')) {
            final errorMessage = data['message'] as String? ?? 
                                data['errorcode'] as String? ?? 
                                'Unknown error occurred';
            debugPrint('Moodle API error: $errorMessage');
            
            if (errorMessage.contains('Access control exception')) {
              throw Exception('Access Denied: Your account does not have permission to use the mobile app. Please contact support.');
            }
            throw Exception(errorMessage);
          }

          // Parse user profile from response
          if (data.containsKey('userid')) {
            return MoodleUserModel.fromJson(data);
          } else {
            throw Exception('User profile data incomplete in response.');
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to get user profile with status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during get user profile: $e');
      rethrow;
    }
  }

  /// Get stored token from secure storage
  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: 'moodle_token');
  }

  /// Delete stored token (logout)
  Future<void> logout() async {
    await _secureStorage.delete(key: 'moodle_token');
    debugPrint('Moodle token deleted');
  }
}
