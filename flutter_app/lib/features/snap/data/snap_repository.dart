import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class SnapRepository {
  final ApiClient _apiClient;

  SnapRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  Future<Map<String, dynamic>> solveProblem({
    required String text,
    String? grade,
    String? subject,
    String language = 'en',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.snapSolve,
        data: {
          'text': text,
          'grade': grade,
          'subject': subject,
          'language': language,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ??
            response.data; // Handle structure variation
      } else {
        throw Exception(response.data['error'] ?? 'Failed to solve problem');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> saveSnap({
    required String title,
    required String content,
    String? subject,
    String? grade,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final response = await _apiClient.post(
        ApiEndpoints.savedResources,
        data: {
          'title': title,
          'content': content, // Full solution content
          'subject': subject ?? 'General',
          'grade': grade ?? 'All',
          'resource_type': 'snap', // Important: distinguish from strategy
        },
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
