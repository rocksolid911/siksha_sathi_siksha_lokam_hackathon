import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

/// YouTube Video Player Screen
/// Plays YouTube videos inside the app
class YouTubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String? channel;

  const YouTubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.channel,
  });

  /// Create from YouTube URL
  factory YouTubePlayerScreen.fromUrl({
    required String url,
    required String title,
    String? channel,
  }) {
    final videoId = YoutubePlayer.convertUrlToId(url) ?? '';
    return YouTubePlayerScreen(
      videoId: videoId,
      title: title,
      channel: channel,
    );
  }

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'hi',
        showLiveFullscreenButton: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
        onReady: () {
          debugPrint('🎬 YouTube Player Ready: ${widget.videoId}');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _isFullScreen
              ? null
              : AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(
                    widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
          body: Column(
            children: [
              // Video Player
              player,

              // Video Info
              if (!_isFullScreen)
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.channel != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.channel!,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.replay_10_rounded,
                              label: '-10s',
                              onTap: () {
                                final currentPos =
                                    _controller.value.position.inSeconds;
                                _controller.seekTo(
                                  Duration(seconds: currentPos - 10),
                                );
                              },
                            ),
                            _buildControlButton(
                              icon: _controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              label: _controller.value.isPlaying
                                  ? 'Pause'
                                  : 'Play',
                              onTap: () {
                                if (_controller.value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                                setState(() {});
                              },
                              isPrimary: true,
                            ),
                            _buildControlButton(
                              icon: Icons.forward_10_rounded,
                              label: '+10s',
                              onTap: () {
                                final currentPos =
                                    _controller.value.position.inSeconds;
                                _controller.seekTo(
                                  Duration(seconds: currentPos + 10),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: isPrimary ? 32 : 24,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
