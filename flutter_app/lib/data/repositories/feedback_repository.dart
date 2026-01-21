import 'package:flutter/foundation.dart';
import '../data_providers/feedback_data_provider.dart';

/// Repository for feedback feature
class FeedbackRepository {
  final FeedbackDataProvider _dataProvider;

  FeedbackRepository({FeedbackDataProvider? dataProvider})
      : _dataProvider = dataProvider ?? FeedbackDataProvider();

  /// Submit feedback for a strategy
  Future<bool> submitFeedback({
    required int strategyId,
    required bool worked,
    int? rating,
    String? notes,
  }) async {
    try {
      final response = await _dataProvider.submitFeedback(
        strategyId: strategyId,
        worked: worked,
        rating: rating,
        notes: notes,
      );

      debugPrint('✅ Feedback submitted: $response');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Failed to submit feedback: $e');
      return false;
    }
  }
}
