/// Teacher context for SOS requests
class TeacherContext {
  final String grade;
  final String subject;
  final int classSize;
  final int timeLeftMinutes;
  final String language;

  const TeacherContext({
    required this.grade,
    required this.subject,
    this.classSize = 35,
    this.timeLeftMinutes = 10,
    this.language = 'hi',
  });

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'subject': subject,
      'class_size': classSize,
      'time_left_minutes': timeLeftMinutes,
      'language': language,
    };
  }
}

/// SOS request payload
class SOSRequest {
  final String query;
  final TeacherContext context;

  const SOSRequest({
    required this.query,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'context': context.toJson(),
    };
  }
}
