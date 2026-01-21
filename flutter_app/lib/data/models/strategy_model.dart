/// Strategy model for teaching strategies
class Strategy {
  final int id;
  final String title;
  final String? titleHi;
  final int timeMinutes;
  final String difficulty;
  final List<String> steps;
  final List<String>? materials;
  final String? ncfAlignment;
  final int successCount;
  final String? videoUrl;
  final String? emoji;

  const Strategy({
    required this.id,
    required this.title,
    this.titleHi,
    required this.timeMinutes,
    required this.difficulty,
    required this.steps,
    this.materials,
    this.ncfAlignment,
    this.successCount = 0,
    this.videoUrl,
    this.emoji,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      titleHi: json['title_hi'],
      timeMinutes: json['time_minutes'] ?? 0,
      difficulty: json['difficulty'] ?? 'easy',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      ncfAlignment: json['ncf_alignment'],
      successCount: json['success_count'] ?? 0,
      videoUrl: json['video_url'],
      emoji: json['emoji'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_hi': titleHi,
      'time_minutes': timeMinutes,
      'difficulty': difficulty,
      'steps': steps,
      'materials': materials,
      'ncf_alignment': ncfAlignment,
      'success_count': successCount,
      'video_url': videoUrl,
      'emoji': emoji,
    };
  }

  Strategy copyWith({
    int? id,
    String? title,
    String? titleHi,
    int? timeMinutes,
    String? difficulty,
    List<String>? steps,
    List<String>? materials,
    String? ncfAlignment,
    int? successCount,
    String? videoUrl,
    String? emoji,
  }) {
    return Strategy(
      id: id ?? this.id,
      title: title ?? this.title,
      titleHi: titleHi ?? this.titleHi,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      difficulty: difficulty ?? this.difficulty,
      steps: steps ?? this.steps,
      materials: materials ?? this.materials,
      ncfAlignment: ncfAlignment ?? this.ncfAlignment,
      successCount: successCount ?? this.successCount,
      videoUrl: videoUrl ?? this.videoUrl,
      emoji: emoji ?? this.emoji,
    );
  }
}
