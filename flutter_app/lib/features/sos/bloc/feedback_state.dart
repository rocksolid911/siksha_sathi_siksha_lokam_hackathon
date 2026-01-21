import 'package:equatable/equatable.dart';

/// Base class for Feedback states
abstract class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

/// Submitting feedback
class FeedbackSubmitting extends FeedbackState {
  final int strategyId;

  const FeedbackSubmitting({required this.strategyId});

  @override
  List<Object?> get props => [strategyId];
}

/// Feedback submitted successfully
class FeedbackSuccess extends FeedbackState {
  final int strategyId;
  final String message;

  const FeedbackSuccess({
    required this.strategyId,
    this.message = 'धन्यवाद! Thank you for your feedback!',
  });

  @override
  List<Object?> get props => [strategyId, message];
}

/// Feedback submission failed
class FeedbackFailure extends FeedbackState {
  final String message;

  const FeedbackFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
