import 'strategy_model.dart';
import 'video_model.dart';

/// Complete SOS response from API
class SOSResponse {
  final bool success;
  final Map<String, dynamic> contextUnderstood;
  final List<Strategy> strategies;
  final List<YouTubeVideo> videos;
  final List<String> ragSources;
  final bool ncfUsed;
  final double confidenceScore;
  final bool offlineAvailable;

  const SOSResponse({
    required this.success,
    required this.contextUnderstood,
    required this.strategies,
    required this.videos,
    this.ragSources = const [],
    this.ncfUsed = false,
    this.confidenceScore = 0.0,
    this.offlineAvailable = false,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) {
    return SOSResponse(
      success: json['success'] ?? false,
      contextUnderstood:
          Map<String, dynamic>.from(json['context_understood'] ?? {}),
      strategies: (json['strategies'] as List<dynamic>?)
              ?.map((e) => Strategy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ragSources: (json['rag_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ncfUsed: json['ncf_used'] ?? false,
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      offlineAvailable: json['offline_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'context_understood': contextUnderstood,
      'strategies': strategies.map((e) => e.toJson()).toList(),
      'videos': videos.map((e) => e.toJson()).toList(),
      'rag_sources': ragSources,
      'ncf_used': ncfUsed,
      'confidence_score': confidenceScore,
      'offline_available': offlineAvailable,
    };
  }
}
