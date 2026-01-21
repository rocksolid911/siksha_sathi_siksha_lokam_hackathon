import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/teacher_context_model.dart';
import '../../../data/repositories/sos_repository.dart';
import 'sos_event.dart';
import 'sos_state.dart';

/// BLoC for SOS feature
class SOSBloc extends Bloc<SOSEvent, SOSState> {
  final SOSRepository _repository;

  // Store last request for refresh
  SOSRequested? _lastRequest;

  SOSBloc({SOSRepository? repository})
      : _repository = repository ?? SOSRepository(),
        super(const SOSInitial()) {
    on<SOSRequested>(_onSOSRequested);
    on<SOSRefreshRequested>(_onSOSRefreshRequested);
    on<SOSReset>(_onSOSReset);
    on<SOSSaveStrategyRequested>(_onSOSSaveStrategyRequested);
    on<SOSUnsaveStrategyRequested>(_onSOSUnsaveStrategyRequested);
    on<SOSSaveAllStrategiesRequested>(_onSOSSaveAllStrategiesRequested);
  }

  // ... (existing handlers)

  Future<void> _onSOSSaveAllStrategiesRequested(
    SOSSaveAllStrategiesRequested event,
    Emitter<SOSState> emit,
  ) async {
    if (state is SOSSuccess) {
      final successState = state as SOSSuccess;

      // Determine context
      final subject = successState.subject;
      final grade = successState.grade;
      final Map<int, int> currentSavedMap =
          Map.from(successState.savedStrategyMap);

      String? videoUrl;
      if (successState.videos.isNotEmpty) {
        videoUrl = successState.videos.first.link;
      }

      // Generate Group ID for this batch
      final groupId = const Uuid().v4();

      // Save each strategy
      for (final strategy in successState.strategies) {
        // Skip if already saved
        if (currentSavedMap.containsKey(strategy.id)) continue;

        try {
          final savedId = await _repository.saveStrategy(
            strategyId: strategy.id,
            title: strategy.title,
            titleHi: strategy.titleHi,
            content: _formatStrategyForSave(strategy),
            subject: subject,
            grade: grade,
            videoUrl: videoUrl,
            groupId: groupId,
          );
          currentSavedMap[strategy.id] = savedId;
        } catch (e) {
          debugPrint('❌ Failed to save strategy ${strategy.title}: $e');
        }
      }

      emit(successState.copyWith(
        savedStrategyMap: currentSavedMap,
      ));
    }
  }

  Future<void> _onSOSRequested(
    SOSRequested event,
    Emitter<SOSState> emit,
  ) async {
    emit(const SOSLoading());

    // Store request for refresh
    _lastRequest = event;

    try {
      // Map Hindi grade/subject to API format
      final gradeNumber = event.grade.replaceAll(RegExp(r'[^\d]'), '');
      final subjectMap = {
        'गणित': 'Math',
        'हिंदी': 'Hindi',
        'English': 'English',
        'विज्ञान': 'Science',
        'सामाजिक विज्ञान': 'Social Science',
      };
      final subjectEnglish = subjectMap[event.subject] ?? event.subject;

      final context = TeacherContext(
        grade: gradeNumber.isNotEmpty ? gradeNumber : '4',
        subject: subjectEnglish,
        timeLeftMinutes: event.timeLeftMinutes,
        language: event.language,
      );

      final response = await _repository.getStrategies(
        query: event.query,
        context: context,
      );

      if (response.success && response.strategies.isNotEmpty) {
        emit(SOSSuccess(
          strategies: response.strategies,
          videos: response.videos,
          isOffline: response.offlineAvailable,
          ncfUsed: response.ncfUsed,
          confidenceScore: response.confidenceScore,
          query: event.query,
          grade: event.grade,
          subject: event.subject,
          timeLeftMinutes: event.timeLeftMinutes,
        ));
      } else {
        emit(SOSFailure(
          message: 'No strategies found',
          fallbackStrategies: response.strategies,
        ));
      }
    } catch (e) {
      debugPrint('❌ SOS BLoC Error: $e');
      emit(SOSFailure(message: e.toString()));
    }
  }

  Future<void> _onSOSRefreshRequested(
    SOSRefreshRequested event,
    Emitter<SOSState> emit,
  ) async {
    // Use last request to refresh
    if (_lastRequest != null) {
      add(_lastRequest!);
    } else if (state is SOSSuccess) {
      final successState = state as SOSSuccess;
      add(SOSRequested(
        query: successState.query,
        grade: successState.grade,
        subject: successState.subject,
        timeLeftMinutes: successState.timeLeftMinutes,
      ));
    }
  }

  void _onSOSReset(
    SOSReset event,
    Emitter<SOSState> emit,
  ) {
    _lastRequest = null;
    emit(const SOSInitial());
  }

  Future<void> _onSOSSaveStrategyRequested(
    SOSSaveStrategyRequested event,
    Emitter<SOSState> emit,
  ) async {
    try {
      final strategy = event.strategy;

      // Determine context from current state if possible
      String? subject;
      String? grade;
      Map<int, int> currentSavedMap = {};

      if (state is SOSSuccess) {
        final successState = state as SOSSuccess;
        subject = successState.subject;
        grade = successState.grade;
        currentSavedMap = Map.from(successState.savedStrategyMap);
      }

      // Find video URL if available in state
      String? videoUrl;
      if (state is SOSSuccess) {
        final successState = state as SOSSuccess;
        if (successState.videos.isNotEmpty) {
          videoUrl = successState.videos.first.link;
          debugPrint('📹 Found video to save: $videoUrl');
        } else {
          debugPrint('⚠️ No videos found in current SOS state to save.');
        }
      } else {
        debugPrint('⚠️ Cannot save video: State is not SOSSuccess.');
      }

      debugPrint(
          '💾 Saving strategy: ${strategy.title} with VideoURL: $videoUrl');

      final savedId = await _repository.saveStrategy(
        strategyId: strategy.id,
        title: strategy.title,
        titleHi: strategy.titleHi,
        content: _formatStrategyForSave(strategy),
        subject: subject ?? 'General',
        grade: grade ?? 'All',
        videoUrl: videoUrl,
      );

      // Update Saved Map
      currentSavedMap[strategy.id] = savedId;

      if (state is SOSSuccess) {
        emit((state as SOSSuccess).copyWith(
          savedStrategyMap: currentSavedMap,
        ));
      }
    } catch (e) {
      debugPrint('❌ Failed to save strategy in Bloc: $e');
    }
  }

  Future<void> _onSOSUnsaveStrategyRequested(
    SOSUnsaveStrategyRequested event,
    Emitter<SOSState> emit,
  ) async {
    try {
      if (state is SOSSuccess) {
        final successState = state as SOSSuccess;
        final currentSavedMap =
            Map<int, int>.from(successState.savedStrategyMap);

        final dbId = currentSavedMap[event.strategyId];
        if (dbId != null) {
          await _repository.unsaveStrategy(dbId);

          currentSavedMap.remove(event.strategyId);
          emit(successState.copyWith(
            savedStrategyMap: currentSavedMap,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to unsave strategy in Bloc: $e');
    }
  }

  String _formatStrategyForSave(dynamic strategy) {
    // Helper to convert steps list to string content
    final buffer = StringBuffer();
    buffer.writeln(strategy.title);
    if (strategy.titleHi != null) buffer.writeln('(${strategy.titleHi})');
    buffer.writeln(
        '\nTime: ${strategy.timeMinutes} min | Difficulty: ${strategy.difficulty}');
    buffer.writeln('\nSTEPS:');
    int i = 1;
    for (var step in strategy.steps) {
      buffer.writeln('$i. $step');
      i++;
    }
    return buffer.toString();
  }
}
