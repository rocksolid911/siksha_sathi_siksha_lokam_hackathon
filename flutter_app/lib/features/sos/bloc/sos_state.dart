import 'package:equatable/equatable.dart';
import '../../../data/models/strategy_model.dart';
import '../../../data/models/video_model.dart';

/// Base class for SOS states
abstract class SOSState extends Equatable {
  const SOSState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SOSInitial extends SOSState {
  const SOSInitial();
}

/// Loading state
class SOSLoading extends SOSState {
  const SOSLoading();
}

/// Success state with strategies and videos
class SOSSuccess extends SOSState {
  final List<Strategy> strategies;
  final List<YouTubeVideo> videos;
  final bool isOffline;
  final String? errorMessage;
  final bool ncfUsed;
  final double confidenceScore;

  // Keep track of original request for refresh
  final String query;
  final String grade;
  final String subject;
  final int timeLeftMinutes;

  const SOSSuccess({
    required this.strategies,
    required this.videos,
    this.isOffline = false,
    this.errorMessage,
    this.ncfUsed = false,
    this.confidenceScore = 0.0,
    required this.query,
    required this.grade,
    required this.subject,
    this.timeLeftMinutes = 10,
    this.savedStrategyMap = const {},
  });

  // Map of client-side Strategy ID to Backend Database ID
  // Used to track which strategies are saved
  final Map<int, int> savedStrategyMap;

  SOSSuccess copyWith({
    List<Strategy>? strategies,
    List<YouTubeVideo>? videos,
    bool? isOffline,
    String? errorMessage,
    bool? ncfUsed,
    double? confidenceScore,
    String? query,
    String? grade,
    String? subject,
    int? timeLeftMinutes,
    Map<int, int>? savedStrategyMap,
  }) {
    return SOSSuccess(
      strategies: strategies ?? this.strategies,
      videos: videos ?? this.videos,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage ?? this.errorMessage,
      ncfUsed: ncfUsed ?? this.ncfUsed,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      query: query ?? this.query,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      timeLeftMinutes: timeLeftMinutes ?? this.timeLeftMinutes,
      savedStrategyMap: savedStrategyMap ?? this.savedStrategyMap,
    );
  }

  @override
  List<Object?> get props => [
        strategies,
        videos,
        isOffline,
        errorMessage,
        ncfUsed,
        confidenceScore,
        query,
        grade,
        subject,
        timeLeftMinutes,
        savedStrategyMap,
      ];
}

/// Failure state
class SOSFailure extends SOSState {
  final String message;
  final List<Strategy>? fallbackStrategies;

  const SOSFailure({
    required this.message,
    this.fallbackStrategies,
  });

  @override
  List<Object?> get props => [message, fallbackStrategies];
}
