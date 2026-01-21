import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/feed_item_model.dart';
import '../bloc/learn_bloc.dart';
import '../bloc/learn_event.dart';
import '../screens/strategy_detail_screen.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;

  const FeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Teacher Info)
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    item.teacherName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.teacherName,
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        '${item.teacherRole} • ${item.teacherSchool ?? "School"}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat.MMMd().format(item.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Content Preview
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StrategyDetailScreen(item: item),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd, vertical: 8),
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.grade.isNotEmpty || item.subject.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          _Tag(text: item.grade),
                          const SizedBox(width: 8),
                          _Tag(text: item.subject),
                          if (item.strategies != null &&
                              item.strategies!.isNotEmpty) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers,
                                      size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text('${item.strategies!.length} Strategies',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  Text(
                    item.title,
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (item.titleHi != null && item.titleHi!.isNotEmpty)
                    Text(
                      item.titleHi!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _getPreviewContent(item.content),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (item.strategies != null && item.strategies!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '+ ${item.strategies!.length - 1} more strategies inside',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: item.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${item.likesCount}',
                  color: item.isLiked ? Colors.red : AppColors.textSecondary,
                  onTap: () {
                    context.read<LearnBloc>().add(LearnStrategyLiked(item.id));
                  },
                ),
                _ActionButton(
                  icon: item.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: '${item.savesCount}',
                  color: item.isSaved
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  onTap: () {
                    context.read<LearnBloc>().add(LearnStrategySaved(item.id));
                  },
                ),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppColors.textSecondary,
                  onTap: () {
                    Share.share(
                      'Check out this teaching strategy: "${item.title}" by ${item.teacherName}\n\n${item.content}\n\nShared via Shiksha Saathi',
                      subject: 'Strategy: ${item.title}',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPreviewContent(String fullContent) {
    // Basic stripping of markdown or just raw text
    return fullContent.replaceAll(RegExp(r'\#|\*'), '');
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
