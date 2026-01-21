import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/video_model.dart';

/// Data provider for resources and YouTube search
class ResourcesDataProvider {
  final ApiClient _apiClient;

  ResourcesDataProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Get quick reference resources
  /// GET /api/v1/resources/
  Future<Map<String, dynamic>> getResources() async {
    final response = await _apiClient.get(ApiEndpoints.resources);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to get resources: ${response.statusCode}');
    }
  }

  /// Search YouTube videos
  /// GET /api/v1/youtube-search/?q=query&limit=5
  Future<List<YouTubeVideo>> searchYouTube({
    required String query,
    int limit = 5,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.youtubeSearch,
      queryParameters: {
        'q': query,
        'limit': limit,
      },
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final videos = (response.data['videos'] as List<dynamic>?)
              ?.map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return videos;
    } else {
      throw Exception('Failed to search YouTube: ${response.statusCode}');
    }
  }

  /// Get health status
  /// GET /api/v1/health/
  Future<Map<String, dynamic>> getHealth() async {
    final response = await _apiClient.get(ApiEndpoints.health);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to get health: ${response.statusCode}');
    }
  }

  /// Get NCF stats
  /// GET /api/v1/ncf-stats/
  Future<Map<String, dynamic>> getNCFStats() async {
    final response = await _apiClient.get(ApiEndpoints.ncfStats);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to get NCF stats: ${response.statusCode}');
    }
  }
}
