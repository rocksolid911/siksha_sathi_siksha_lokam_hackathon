import 'package:equatable/equatable.dart';

abstract class LearnEvent extends Equatable {
  const LearnEvent();

  @override
  List<Object> get props => [];
}

class LearnFeedRequested extends LearnEvent {
  const LearnFeedRequested();
}

class LearnStrategyLiked extends LearnEvent {
  final int strategyId;
  const LearnStrategyLiked(this.strategyId);

  @override
  List<Object> get props => [strategyId];
}

class LearnStrategySaved extends LearnEvent {
  final int strategyId;
  const LearnStrategySaved(this.strategyId);

  @override
  List<Object> get props => [strategyId];
}
