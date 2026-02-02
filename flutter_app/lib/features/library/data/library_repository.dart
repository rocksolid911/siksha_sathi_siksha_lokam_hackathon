import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shiksha_saathi/core/constants/app_colors.dart';
import 'package:shiksha_saathi/core/network/api_client.dart';
import 'package:shiksha_saathi/core/network/api_endpoints.dart';

class LibraryRepository {
  final ApiClient _apiClient;

  LibraryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  // Real API call for "Saved Strategies"
  Future<List<Map<String, dynamic>>> getSavedStrategies() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _apiClient.get(
        ApiEndpoints.savedResources,
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  // Delete saved strategy
  Future<bool> deleteSavedStrategy(int id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final response = await _apiClient.delete(
        ApiEndpoints.savedResources,
        queryParameters: {'id': id},
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Save a resource (Strategy, Snap, or PDF)
  Future<Map<String, dynamic>> saveResource(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      final response = await _apiClient.post(
        ApiEndpoints.savedResources,
        data: data,
        options: Options(
          headers: {
            'X-Firebase-UID': user.uid,
          },
        ),
      );

      return response.data;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Mock data for "Static Resources" (NCF, Guidelines)
  List<Map<String, dynamic>> getStaticResources() {
    return [
      {
        'id': 'ncf_2023',
        'title': 'National Curriculum Framework 2023',
        'subtitle': 'Foundation Stage Guidelines',
        'type': 'PDF',
        'icon': 'book_open',
        'color': AppColors.primary,
      },
      {
        'id': 'toys_manual',
        'title': 'Jadui Pitara Handbook',
        'subtitle': 'Toy-based Pedagogy',
        'type': 'PDF',
        'icon': 'shapes',
        'color': AppColors.secondary,
      },
      {
        'id': 'fln_mission',
        'title': 'NIPUN Bharat Guidelines',
        'subtitle': 'FLN Implementation',
        'type': 'PDF',
        'icon': 'target',
        'color': AppColors.accent,
      },
    ];
  }
}
