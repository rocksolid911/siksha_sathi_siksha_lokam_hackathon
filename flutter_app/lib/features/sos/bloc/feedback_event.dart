import 'package:equatable/equatable.dart';

/// Base class for Feedback events
abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Submit feedback for a strategy
class FeedbackSubmitted extends FeedbackEvent {
  final int strategyId;
  final bool worked;
  final int? rating;
  final String? notes;

  const FeedbackSubmitted({
    required this.strategyId,
    required this.worked,
    this.rating,
    this.notes,
  });

  @override
  List<Object?> get props => [strategyId, worked, rating, notes];
}

/// Event: Reset feedback state
class FeedbackReset extends FeedbackEvent {
  const FeedbackReset();
}
