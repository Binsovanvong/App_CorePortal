import 'package:core_portal/core/api/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart'; // <-- CRITICAL: For reading the token

class AuthService {
  final ApiService apiService = ApiService();

  Future<Map<String, dynamic>> loginService({
    required String username,
    required String password,
  }) async {
    var response = await apiService.post(
      endpoint: '/api/mobile/auth/login',
      data: {'username': username, 'password': password},
    );

    return response;
  }

  // Changed return type to Future<dynamic> to match apiService.get()
  Future<dynamic> fetchProfile() async {
    try {
      final box = GetStorage();
      final String? token = box.read(
        'token',
      ); // Retrieve token from local storage

      return await apiService.get(
        endpoint: '/api/mobile/accounts/profile',
        headers: {
          'authorization':
              'Bearer $token', // Pass token to match your Swagger spec
        },
      );
    } on DioException catch (e) {
      debugPrint("PROFILE STATUS: ${e.response?.statusCode}");
      debugPrint("PROFILE BODY: ${e.response?.data}");
      rethrow;
    }
  }

  Future<dynamic> logoutService() async {
    try {
      final box = GetStorage();
      final String? token = box.read(
        'token',
      ); // Retrieve token from local storage

      return await apiService.post(
        endpoint: '/api/mobile/auth/logout',
        headers: {'authorization': 'Bearer $token'},
      );
    } on DioException catch (e) {
      debugPrint("LOGOUT STATUS: ${e.response?.statusCode}");
      debugPrint("LOGOUT BODY: ${e.response?.data}");
      rethrow;
    }
  }

  Future<dynamic> fetchApps() async {
    try {
      final box = GetStorage();
      final String? token = box.read(
        'token',
      ); // Retrieve token from local storage

      return await apiService.get(
        endpoint: '/api/mobile/portals/apps',
        headers: {'authorization': 'Bearer $token'},
      );
    } on DioException catch (e) {
      debugPrint("APPS STATUS: ${e.response?.statusCode}");
      debugPrint("APPS BODY: ${e.response?.data}");
      rethrow;
    }
  }

  Future<dynamic> changePasswordService({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final box = GetStorage();
      final String? token = box.read(
        'token',
      ); // Retrieve token from local storage

      return await apiService.put(
        endpoint: '/api/mobile/accounts/change-password',
        headers: {'authorization': 'Bearer $token'},
        data: {
          'username': username,
          'current_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      debugPrint("CHANGE PASSWORD STATUS: ${e.response?.statusCode}");
      debugPrint("CHANGE PASSWORD BODY: ${e.response?.data}");
      rethrow;
    }
  }

  Future<dynamic> fetchAnnouncements() async {
    try {
      final box = GetStorage();
      final String? token = box.read('token');

      return await apiService.get(
        endpoint: '/api/mobile/portals/announcements',
        headers: {
          if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      );
    } on DioException catch (e) {
      debugPrint("ANNOUNCEMENTS STATUS: ${e.response?.statusCode}");
      debugPrint("ANNOUNCEMENTS BODY: ${e.response?.data}");
      rethrow;
    }
  }
}
