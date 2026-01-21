import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/sos_response_model.dart';
import '../models/teacher_context_model.dart';

/// Data provider for SOS API calls
class SOSDataProvider {
  final ApiClient _apiClient;

  SOSDataProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Get teaching strategies from API
  /// POST /api/v1/sos/
  Future<SOSResponse> getStrategies({
    required String query,
    required TeacherContext context,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sos,
        data: {
          'query': query,
          'context': context.toJson(),
        },
      );

      if (response.statusCode == 200) {
        return SOSResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get strategies: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save a strategy to the user's profile and returns the Saved Strategy ID (database ID)
  /// POST /api/v1/saved-resources/
  Future<int> saveStrategy({
    required int
        strategyId, // Placeholder if backend needs it, or use full object
    required String title,
    required String content,
    String? titleHi,
    String? subject,
    String? grade,
    String? videoUrl,
    String? groupId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final response = await _apiClient.post(
        ApiEndpoints.savedResources,
        data: {
          'title': title,
          'title_hi': titleHi,
          'content': content,
          'subject': subject,
          'grade': grade,
          'video_url': videoUrl,
          'group_id': groupId,
        },
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );

      return response.data['id'];
    } catch (e) {
      rethrow;
    }
  }

  /// Unsave a strategy
  /// DELETE /api/v1/saved-resources/?id=<id>
  Future<void> deleteStrategy(int id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      await _apiClient.delete(
        ApiEndpoints.savedResources,
        queryParameters: {'id': id},
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
