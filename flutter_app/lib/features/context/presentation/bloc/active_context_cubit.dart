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
}
