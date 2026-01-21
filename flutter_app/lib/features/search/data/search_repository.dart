import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class SearchRepository {
  final Dio _dio;

  SearchRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search/',
        queryParameters: {'q': query},
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['results']);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedResources() async {
    try {
      final response = await _dio.get('/saved-resources/');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch saved resources: $e');
    }
  }
}
