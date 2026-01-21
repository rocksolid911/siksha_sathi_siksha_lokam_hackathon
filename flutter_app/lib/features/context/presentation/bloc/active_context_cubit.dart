import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/preferences_repository.dart';
import 'active_context_state.dart';

class ActiveContextCubit extends Cubit<ActiveContextState> {
  final PreferencesRepository _preferencesRepository;

  ActiveContextCubit({required PreferencesRepository preferencesRepository})
      : _preferencesRepository = preferencesRepository,
        super(const ActiveContextState());

  Future<void> loadContext() async {
    try {
      final contextData = await _preferencesRepository.getActiveContext();
      final grade = contextData['grade'];
      final subject = contextData['subject'];

      if (grade != null && subject != null) {
        emit(state.copyWith(
          activeGrade: grade,
          activeSubject: subject,
          isInitialized: true,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isInitialized: false,
          isLoading: false,
        ));
      }
    } catch (e) {
      // Handle error or fallback
      emit(state.copyWith(
        isInitialized: false,
        isLoading: false,
      ));
    }
  }

  Future<void> updateContext({
    required String grade,
    required String subject,
  }) async {
    await _preferencesRepository.saveActiveContext(
      grade: grade,
      subject: subject,
    );
    emit(state.copyWith(
      activeGrade: grade,
      activeSubject: subject,
      isInitialized: true,
    ));
  }

  Future<void> clearContext() async {
    // We might not want to clear from disk if we want to remember for next login of SAME user,
    // but without user ID keying, it's safer to clear or just reset state in memory.
    // If we want to force SetupScreen for new login, we should clear memory state.
    // If we want to clear disk too:
    // await _preferencesRepository.clearAll(); // Too aggressive?
    // Let's just reset memory state to force check or setup.
    // Actually, if we leave it on disk, loadContext() will just reload it.
    // So we should probably clear the specific keys or move to user-keyed prefs.
    // For now, let's clear the active context keys.
    await _preferencesRepository.saveActiveContext(
        grade: '', subject: ''); // Or add clear method to repo

    // Better: emit uninitialized
    emit(const ActiveContextState(isInitialized: false, isLoading: false));
  }
}
