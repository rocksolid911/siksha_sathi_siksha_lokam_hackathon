import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/feed_item_model.dart';
import '../bloc/learn_bloc.dart';
import '../bloc/learn_event.dart';

class StrategyDetailScreen extends StatefulWidget {
  final FeedItem item;

  const StrategyDetailScreen({super.key, required this.item});

  @override
  State<StrategyDetailScreen> createState() => _StrategyDetailScreenState();
}

class _StrategyDetailScreenState extends State<StrategyDetailScreen> {
  YoutubePlayerController? _videoController;
  late FeedItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item.videoUrl != null && _item.videoUrl!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(_item.videoUrl!);
      if (videoId != null) {
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Strategy Details', style: AppTextStyles.titleLarge),
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player or Placeholder
            if (_videoController != null)
              YoutubePlayer(
                controller: _videoController!,
                showVideoProgressIndicator: true,
                progressColors: const ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: AppColors.primary,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Metadata
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item.title,
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_item.titleHi != null)
                              Text(
                                _item.titleHi!,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Like/Save Buttons
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _item.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _item.isLiked
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              context
                                  .read<LearnBloc>()
                                  .add(LearnStrategyLiked(_item.id));
                              setState(() {
                                // Optimistic update for local state in this screen
                                _item = _item.copyWith(
                                  isLiked: !_item.isLiked,
                                  likesCount: _item.isLiked
                                      ? _item.likesCount - 1
                                      : _item.likesCount + 1,
                                );
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _item.isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _item.isSaved
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              context
                                  .read<LearnBloc>()
                                  .add(LearnStrategySaved(_item.id));
                              setState(() {
                                _item = _item.copyWith(
                                  isSaved: !_item.isSaved,
                                  savesCount: _item.isSaved
                                      ? _item.savesCount - 1
                                      : _item.savesCount + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingSm),

                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_item.grade.isNotEmpty)
                        _Tag(text: 'Grade ${_item.grade}'),
                      if (_item.subject.isNotEmpty) _Tag(text: _item.subject),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Teacher Info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _item.teacherName.isNotEmpty
                              ? _item.teacherName[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_item.teacherName,
                              style: AppTextStyles.titleMedium),
                          if (_item.teacherSchool != null)
                            Text(_item.teacherSchool!,
                                style: AppTextStyles.caption),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd().format(_item.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Content
                  Text(
                    'Strategy Description',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _item.content,
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                  ),

                  // Related Strategies (Grouped)
                  if (_item.strategies != null &&
                      _item.strategies!.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Related Strategies from this Session',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ..._item.strategies!
                        .where((s) => s.id != _item.id)
                        .map((strategy) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strategy.title,
                                      style: AppTextStyles.titleMedium),
                                  if (strategy.titleHi != null)
                                    Text(strategy.titleHi!,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                color:
                                                    AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Text(strategy.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
