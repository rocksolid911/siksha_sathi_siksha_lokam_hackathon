import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  static const String _keyActiveGrade = 'active_grade';
  static const String _keyActiveSubject = 'active_subject';
  static const String _keyPreferredLanguage = 'preferred_language';

  // Singleton pattern is optional if using Dependency Injection,
  // but keeping it simple for now or just using DI via RepositoryProvider.
  // We'll rely on DI in App.

  Future<void> saveActiveContext({
    required String grade,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveGrade, grade);
    await prefs.setString(_keyActiveSubject, subject);
  }

  Future<Map<String, String?>> getActiveContext() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'grade': prefs.getString(_keyActiveGrade),
      'subject': prefs.getString(_keyActiveSubject),
    };
  }

  Future<void> clearActiveContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveGrade);
    await prefs.remove(_keyActiveSubject);
  }

  Future<void> savePreferredLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferredLanguage, languageCode);
  }

  Future<String?> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPreferredLanguage);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
