import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Data provider for feedback API calls
class FeedbackDataProvider {
  final ApiClient _apiClient;

  FeedbackDataProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Submit feedback for a strategy
  /// POST /api/v1/feedback/
  Future<Map<String, dynamic>> submitFeedback({
    required int strategyId,
    required bool worked,
    int? rating,
    String? notes,
    Map<String, dynamic>? context,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.feedback,
      data: {
        'strategy_id': strategyId,
        'worked': worked,
        if (rating != null) 'rating': rating,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (context != null) 'context': context,
      },
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to submit feedback: ${response.statusCode}');
    }
  }
}
