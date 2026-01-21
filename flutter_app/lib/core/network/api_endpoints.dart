/// API Endpoint definitions
class ApiEndpoints {
  ApiEndpoints._();

  // Health check
  static const String health = '/health/';

  // SOS - Main feature
  static const String sos = '/sos/';
  static const String snapSolve = '/snap/solve/';

  // Feedback
  static const String feedback = '/feedback/';

  // Strategies
  static const String strategies = '/strategies/';
  static String strategyDetail(int id) => '/strategies/$id/';

  // Resources
  static const String resources = '/resources/';

  // NCF Stats
  static const String ncfStats = '/ncf-stats/';

  // YouTube Search
  static const String youtubeSearch = '/youtube-search/';

  // Admin
  static const String indexPdf = '/admin/index-pdf/';

  // Saved Resources
  static const String savedResources = '/saved-resources/';
}
