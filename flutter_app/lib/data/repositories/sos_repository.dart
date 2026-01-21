import 'package:flutter/foundation.dart';
import '../data_providers/sos_data_provider.dart';
import '../models/sos_response_model.dart';
import '../models/strategy_model.dart';
import '../models/teacher_context_model.dart';

/// Repository for SOS feature with caching and fallback support
class SOSRepository {
  final SOSDataProvider _dataProvider;

  // Cache for offline support
  SOSResponse? _lastResponse;

  SOSRepository({SOSDataProvider? dataProvider})
      : _dataProvider = dataProvider ?? SOSDataProvider();

  /// Get teaching strategies with offline fallback
  Future<SOSResponse> getStrategies({
    required String query,
    required TeacherContext context,
  }) async {
    try {
      final response = await _dataProvider.getStrategies(
        query: query,
        context: context,
      );

      // Cache successful response
      _lastResponse = response;

      debugPrint('✅ Got ${response.strategies.length} strategies from API');
      return response;
    } catch (e) {
      debugPrint('❌ API failed, using fallback: $e');

      // Return cached response if available
      if (_lastResponse != null) {
        return _lastResponse!;
      }

      // Return fallback strategies
      return SOSResponse(
        success: true,
        contextUnderstood: {
          'grade': context.grade,
          'subject': context.subject,
          'challenge': query,
        },
        strategies: _getFallbackStrategies(),
        videos: [],
        offlineAvailable: true,
      );
    }
  }

  /// Fallback strategies for offline mode
  List<Strategy> _getFallbackStrategies() {
    return [
      const Strategy(
        id: 1,
        title: 'Roti Division Method',
        titleHi: 'रोटी विभाजन विधि',
        timeMinutes: 2,
        difficulty: 'easy',
        emoji: '🍞',
        steps: [
          'Draw a full roti on board, label it as "1"',
          'Divide it in half, point to each half as "1/2"',
          'Ask: "If 2 friends share, how much does each get?"',
        ],
        materials: ['blackboard', 'chalk'],
        ncfAlignment: 'Concrete to abstract (NCF 2023)',
        successCount: 156,
      ),
      const Strategy(
        id: 2,
        title: 'Pair-Share Tiffin Count',
        titleHi: 'जोड़ी में टिफिन गिनती',
        timeMinutes: 5,
        difficulty: 'medium',
        emoji: '🍱',
        steps: [
          'Pair students together',
          'Ask them to count tiffin items together',
          'One student takes half, both count their portions',
          'Write on slate: my_items / total_items',
        ],
        materials: ['students tiffins', 'slate'],
        ncfAlignment: 'Peer learning (NCF 2023)',
        successCount: 89,
      ),
      const Strategy(
        id: 3,
        title: 'Pizza Circle Visual',
        titleHi: 'पिज्जा वृत्त चित्र',
        timeMinutes: 1,
        difficulty: 'easy',
        emoji: '🍕',
        steps: [
          'Draw 3 pizza circles on the board',
          'Color half of each circle with chalk',
          'Point and say: "Colored part is 1/2 of pizza"',
        ],
        materials: ['blackboard', 'colored chalk'],
        ncfAlignment: 'Visual representation (NCF 2023)',
        successCount: 201,
      ),
    ];
  }

  /// Get cached response
  SOSResponse? get cachedResponse => _lastResponse;

  /// Clear cache
  void clearCache() {
    _lastResponse = null;
  }

  /// Save a strategy
  Future<int> saveStrategy({
    required int strategyId,
    required String title,
    required String content,
    String? titleHi,
    String? subject,
    String? grade,
    String? videoUrl,
    String? groupId,
  }) async {
    try {
      final savedId = await _dataProvider.saveStrategy(
        strategyId: strategyId,
        title: title,
        content: content,
        titleHi: titleHi,
        subject: subject,
        grade: grade,
        videoUrl: videoUrl,
        groupId: groupId,
      );
      debugPrint('✅ Strategy saved successfully with ID: $savedId');
      return savedId;
    } catch (e) {
      debugPrint('❌ Failed to save strategy: $e');
      throw Exception('Failed to save strategy: $e');
    }
  }

  /// Unsave a strategy
  Future<void> unsaveStrategy(int id) async {
    try {
      await _dataProvider.deleteStrategy(id);
      debugPrint('✅ Strategy unsaved successfully');
    } catch (e) {
      debugPrint('❌ Failed to unsave strategy: $e');
      throw Exception('Failed to unsave strategy: $e');
    }
  }
}
