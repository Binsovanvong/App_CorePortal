import 'package:core_portal/core/api/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ApiService {
final ApiConfig apiConfig = ApiConfig();

  Future<dynamic> post({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      var response = await apiConfig.dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("Error ${e.toString()}");
      rethrow;
    }
  }

  // Inside api_service.dart
  Future<dynamic> get({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers, // <-- Add this parameter
  }) async {
    try {
      var response = await apiConfig.dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers), // <-- Pass headers to Dio
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("Error ${e.toString()}");
      rethrow;
    }
  }

  Future<dynamic> put({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      var response = await apiConfig.dio.put(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("Error ${e.toString()}");
      rethrow;
    }
  }
}
