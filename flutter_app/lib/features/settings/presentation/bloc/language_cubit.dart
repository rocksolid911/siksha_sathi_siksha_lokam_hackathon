import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/preferences_repository.dart';

class LanguageCubit extends Cubit<Locale> {
  final PreferencesRepository _preferencesRepository;

  LanguageCubit({required PreferencesRepository preferencesRepository})
      : _preferencesRepository = preferencesRepository,
        super(const Locale('en')) {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final languageCode = await _preferencesRepository.getPreferredLanguage();
    if (languageCode != null) {
      emit(Locale(languageCode));
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    await _preferencesRepository.savePreferredLanguage(locale.languageCode);
    emit(locale);
  }
}
