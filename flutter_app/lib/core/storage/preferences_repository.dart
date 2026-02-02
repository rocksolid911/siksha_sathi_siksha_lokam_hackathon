import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  static const String _keyActiveGrade = 'active_grade';
  static const String _keyActiveSubject = 'active_subject';
  static const String _keyStudentCount = 'student_count';
  static const String _keyPreferredLanguage = 'preferred_language';

  // Singleton pattern is optional if using Dependency Injection,
  // but keeping it simple for now or just using DI via RepositoryProvider.
  // We'll rely on DI in App.

  Future<void> saveActiveContext({
    required String grade,
    required String subject,
    int? studentCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveGrade, grade);
    await prefs.setString(_keyActiveSubject, subject);
    if (studentCount != null) {
      await prefs.setInt(_keyStudentCount, studentCount);
    }
  }

  Future<Map<String, dynamic>> getActiveContext() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'grade': prefs.getString(_keyActiveGrade),
      'subject': prefs.getString(_keyActiveSubject),
      'studentCount': prefs.getInt(_keyStudentCount),
    };
  }

  Future<void> clearActiveContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveGrade);
    await prefs.remove(_keyActiveSubject);
    await prefs.remove(_keyStudentCount);
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
