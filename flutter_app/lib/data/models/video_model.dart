/// YouTube video model for video recommendations
class YouTubeVideo {
  final String id;
  final String title;
  final String? thumbnail;
  final String link;
  final String channel;
  final String? duration;

  const YouTubeVideo({
    required this.id,
    required this.title,
    this.thumbnail,
    required this.link,
    required this.channel,
    this.duration,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'],
      link: json['link'] ?? '',
      channel: json['channel'] ?? 'Unknown',
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'link': link,
      'channel': channel,
      'duration': duration,
    };
  }
}
