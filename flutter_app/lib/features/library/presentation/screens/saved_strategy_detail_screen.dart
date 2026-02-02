import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shiksha_saathi/core/constants/app_colors.dart';
import 'package:shiksha_saathi/core/constants/app_text_styles.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';
import '../../../../features/search/presentation/screens/pdf_viewer_screen.dart';
import '../../../../features/search/presentation/screens/video_player_screen.dart';

class SavedStrategyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> strategy;
  final VoidCallback? onDelete;

  const SavedStrategyDetailScreen({
    super.key,
    required this.strategy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = strategy['title'] ?? 'Strategy';
    final titleHi = strategy['title_hi'];
    final content = strategy['content'] as String? ?? '';
    final videoUrl = strategy['video_url'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Strategy'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove from Library?'),
                    content: const Text(
                        'Are you sure you want to remove this strategy?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          onDelete!();
                          Navigator.pop(context); // Close detail screen
                        },
                        child: const Text('Remove',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(title, style: AppTextStyles.headlineMedium),
            if (titleHi != null && titleHi.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(titleHi,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.neutral600)),
            ],

            const SizedBox(height: 16),

            // Tags
            Row(
              children: [
                _buildTag(strategy['subject'] ?? 'General', AppColors.primary),
                const SizedBox(width: 8),
                _buildTag(strategy['grade'] ?? 'All', AppColors.secondary),
              ],
            ),

            const SizedBox(height: 24),

            // PDF or Video Button
            if (strategy['type'] == 'pdf' ||
                (videoUrl != null &&
                    videoUrl.toLowerCase().endsWith('.pdf'))) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.fileText,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text('Saved PDF Resource',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                              url: videoUrl ?? '',
                              title: title,
                            ),
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.pdfViewer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (videoUrl != null && videoUrl.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.youtube,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Watch Related Video',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
                        if (videoId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoId: videoId,
                                title: title,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid video URL')),
                          );
                        }
                      },
                      child: const Text('Play Video'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Content
            Text('Strategy Details', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
