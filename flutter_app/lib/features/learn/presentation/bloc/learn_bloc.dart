import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/learn_repository.dart';
import 'learn_event.dart';
import 'learn_state.dart';

class LearnBloc extends Bloc<LearnEvent, LearnState> {
  final LearnRepository _repository;

  LearnBloc({LearnRepository? repository})
      : _repository = repository ?? LearnRepository(),
        super(LearnInitial()) {
    on<LearnFeedRequested>(_onFeedRequested);
    on<LearnStrategyLiked>(_onStrategyLiked);
    on<LearnStrategySaved>(_onStrategySaved);
  }

  Future<void> _onFeedRequested(
    LearnFeedRequested event,
    Emitter<LearnState> emit,
  ) async {
    emit(LearnLoading());
    try {
      final feed = await _repository.getFeed();
      emit(LearnLoaded(feed: feed));
    } catch (e) {
      emit(LearnError(e.toString()));
    }
  }

  Future<void> _onStrategyLiked(
    LearnStrategyLiked event,
    Emitter<LearnState> emit,
  ) async {
    if (state is LearnLoaded) {
      final currentState = state as LearnLoaded;
      final updatedFeed = currentState.feed.map((item) {
        if (item.id == event.strategyId) {
          // Optimistic update
          final newCount =
              item.isLiked ? item.likesCount - 1 : item.likesCount + 1;
          return item.copyWith(
            isLiked: !item.isLiked,
            likesCount: newCount,
          );
        }
        return item;
      }).toList();

      emit(currentState.copyWith(feed: updatedFeed));

      try {
        await _repository.likeStrategy(event.strategyId);
      } catch (e) {
        // Revert on failure (complex to implement perfectly without refetch, keeping simple for now)
      }
    }
  }

  Future<void> _onStrategySaved(
    LearnStrategySaved event,
    Emitter<LearnState> emit,
  ) async {
    if (state is LearnLoaded) {
      final currentState = state as LearnLoaded;
      final updatedFeed = currentState.feed.map((item) {
        if (item.id == event.strategyId) {
          return item.copyWith(
            isSaved: true,
            savesCount: item.savesCount + 1,
          );
        }
        return item;
      }).toList();

      emit(currentState.copyWith(feed: updatedFeed));

      try {
        await _repository.saveStrategy(event.strategyId);
      } catch (e) {
        // Revert
      }
    }
  }
}
