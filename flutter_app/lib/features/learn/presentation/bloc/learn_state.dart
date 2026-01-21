import 'package:equatable/equatable.dart';
import '../../data/models/feed_item_model.dart';

abstract class LearnState extends Equatable {
  const LearnState();

  @override
  List<Object> get props => [];
}

class LearnInitial extends LearnState {}

class LearnLoading extends LearnState {}

class LearnLoaded extends LearnState {
  final List<FeedItem> feed;
  final bool hasReachedMax;

  const LearnLoaded({
    required this.feed,
    this.hasReachedMax = false,
  });

  LearnLoaded copyWith({
    List<FeedItem>? feed,
    bool? hasReachedMax,
  }) {
    return LearnLoaded(
      feed: feed ?? this.feed,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [feed, hasReachedMax];
}

class LearnError extends LearnState {
  final String message;
  const LearnError(this.message);

  @override
  List<Object> get props => [message];
}
