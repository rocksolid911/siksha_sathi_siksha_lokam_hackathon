import 'package:equatable/equatable.dart';

/// Base class for SOS events
abstract class SOSEvent extends Equatable {
  const SOSEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Request teaching strategies
class SOSRequested extends SOSEvent {
  final String query;
  final String grade;
  final String subject;
  final int timeLeftMinutes;
  final String language;

  const SOSRequested({
    required this.query,
    required this.grade,
    required this.subject,
    this.timeLeftMinutes = 10,
    this.language = 'hi',
  });

  @override
  List<Object?> get props => [query, grade, subject, timeLeftMinutes, language];
}

/// Event: Request different strategies (refresh)
class SOSRefreshRequested extends SOSEvent {
  const SOSRefreshRequested();
}

/// Event: Reset SOS state
class SOSReset extends SOSEvent {
  const SOSReset();
}

/// Event: Save a strategy
class SOSSaveStrategyRequested extends SOSEvent {
  final dynamic
      strategy; // Use dynamic to avoid import cycle or duplicate model import here

  const SOSSaveStrategyRequested(this.strategy);

  @override
  List<Object?> get props => [strategy];
}

/// Event: Unsave a strategy
class SOSUnsaveStrategyRequested extends SOSEvent {
  final int strategyId; // The Client/Strategy ID (1, 2, 3...)

  const SOSUnsaveStrategyRequested(this.strategyId);

  @override
  List<Object?> get props => [strategyId];
}

/// Event: Save all strategies (e.g., "I'll Try These")
class SOSSaveAllStrategiesRequested extends SOSEvent {
  const SOSSaveAllStrategiesRequested();
}
