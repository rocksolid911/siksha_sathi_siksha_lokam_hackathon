import 'package:equatable/equatable.dart';

class FeedItem extends Equatable {
  final int id;
  final String title;
  final String? titleHi;
  final String content;
  final String subject;
  final String grade;
  final String? videoUrl;
  final DateTime createdAt;
  final int likesCount;
  final int savesCount;
  final bool isPublic;
  final String teacherName;
  final String? teacherSchool;
  final String? teacherRole;
  final bool isLiked;
  final bool isSaved;
  final String? groupId;
  final List<FeedItem>? strategies; // Grouped strategies

  const FeedItem({
    required this.id,
    required this.title,
    this.titleHi,
    required this.content,
    required this.subject,
    required this.grade,
    this.videoUrl,
    required this.createdAt,
    required this.likesCount,
    required this.savesCount,
    required this.isPublic,
    required this.teacherName,
    this.teacherSchool,
    this.teacherRole,
    this.isLiked = false,
    this.isSaved = false,
    this.groupId,
    this.strategies,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    var rawStrategies = json['strategies'] as List?;
    List<FeedItem>? parsedStrategies;
    if (rawStrategies != null) {
      parsedStrategies =
          rawStrategies.map((i) => FeedItem.fromJson(i)).toList();
    }

    return FeedItem(
      id: json['id'],
      title: json['title'],
      titleHi: json['title_hi'],
      content: json['content'],
      subject: json['subject'] ?? 'General',
      grade: json['grade'] ?? 'All',
      videoUrl: json['video_url'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      isPublic: json['is_public'] ?? true,
      teacherName: json['teacher_name'] ?? 'Teacher',
      teacherSchool: json['teacher_school'],
      teacherRole: json['teacher_role'],
      groupId: json['group_id'],
      strategies: parsedStrategies,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }

  // For copying with updates (optimistic UI)
  FeedItem copyWith({
    int? likesCount,
    int? savesCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return FeedItem(
      id: id,
      title: title,
      titleHi: titleHi,
      content: content,
      subject: subject,
      grade: grade,
      videoUrl: videoUrl,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      savesCount: savesCount ?? this.savesCount,
      isPublic: isPublic,
      teacherName: teacherName,
      teacherSchool: teacherSchool,
      teacherRole: teacherRole,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      groupId: groupId,
      strategies: strategies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        likesCount,
        savesCount,
        isLiked,
        isSaved,
        groupId,
        strategies,
      ];
}
