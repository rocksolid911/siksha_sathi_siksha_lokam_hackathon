import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/feed_item_model.dart';
import 'package:flutter/foundation.dart';

class LearnRepository {
  final ApiClient _apiClient;

  LearnRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  // GET /api/v1/feed/
  Future<List<FeedItem>> getFeed() async {
    try {
      final response = await _apiClient.get(
        // Assuming ApiEndpoints doesn't have it yet, using raw string for now or adding it
        '/feed/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['feed'];
        return data.map((json) => FeedItem.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch feed',
        );
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
      rethrow; // Or return empty list based on error handling policy
    }
  }

  // POST /api/v1/strategies/<id>/like/
  Future<int> likeStrategy(int id) async {
    try {
      final response = await _apiClient.post(
        '/strategies/$id/like/',
      );
      if (response.statusCode == 200) {
        return response.data['likes_count'];
      }
      throw Exception('Failed to like strategy');
    } catch (e) {
      debugPrint('Error liking strategy: $e');
      rethrow;
    }
  }

  // POST /api/v1/strategies/<id>/save/
  Future<int> saveStrategy(int id) async {
    try {
      final response = await _apiClient.post(
        '/strategies/$id/save/',
      );
      if (response.statusCode == 200) {
        return response.data['saves_count'];
      }
      throw Exception('Failed to save strategy');
    } catch (e) {
      debugPrint('Error saving strategy: $e');
      rethrow;
    }
  }

  // GET /api/v1/trending/
  Future<List<FeedItem>> getTrending({String? grade, String? subject}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (grade != null) queryParams['grade'] = grade;
      if (subject != null) queryParams['subject'] = subject;

      final response = await _apiClient.get(
        '/trending/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['trending'];
        return data.map((json) => FeedItem.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to fetch trending',
      );
    } catch (e) {
      debugPrint('Error fetching trending: $e');
      // Return empty list on error to not crash UI
      return [];
    }
  }
}
