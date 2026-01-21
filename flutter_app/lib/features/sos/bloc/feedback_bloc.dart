import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/feedback_repository.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

/// BLoC for feedback feature
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository _repository;

  FeedbackBloc({FeedbackRepository? repository})
      : _repository = repository ?? FeedbackRepository(),
        super(const FeedbackInitial()) {
    on<FeedbackSubmitted>(_onFeedbackSubmitted);
    on<FeedbackReset>(_onFeedbackReset);
  }

  Future<void> _onFeedbackSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackSubmitting(strategyId: event.strategyId));

    try {
      final success = await _repository.submitFeedback(
        strategyId: event.strategyId,
        worked: event.worked,
        rating: event.rating,
        notes: event.notes,
      );

      if (success) {
        emit(FeedbackSuccess(strategyId: event.strategyId));
      } else {
        emit(const FeedbackFailure(message: 'Failed to submit feedback'));
      }
    } catch (e) {
      debugPrint('❌ Feedback BLoC Error: $e');
      emit(FeedbackFailure(message: e.toString()));
    }
  }

  void _onFeedbackReset(
    FeedbackReset event,
    Emitter<FeedbackState> emit,
  ) {
    emit(const FeedbackInitial());
  }
}
