import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/strategy_model.dart';
import '../../../data/models/video_model.dart';
import '../bloc/sos_bloc.dart';
import '../bloc/sos_event.dart';
import '../bloc/sos_state.dart';

/// SOS Response Screen with BLoC state management
class SOSResponseScreen extends StatelessWidget {
  final String query;
  final String grade;
  final String subject;
  final int timeLeft;

  const SOSResponseScreen({
    super.key,
    required this.query,
    required this.grade,
    required this.subject,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SOSBloc()
        ..add(SOSRequested(
          query: query,
          grade: grade,
          subject: subject,
          timeLeftMinutes: timeLeft,
        )),
      child: const _SOSResponseView(),
    );
  }
}

class _SOSResponseView extends StatelessWidget {
  const _SOSResponseView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: BlocBuilder<SOSBloc, SOSState>(
        builder: (context, state) {
          if (state is SOSLoading) {
            return _buildLoading();
          } else if (state is SOSSuccess) {
            return _SOSContent(
              strategies: state.strategies,
              videos: state.videos,
              isOffline: state.isOffline,
              errorMessage: state.errorMessage,
              query: state.query,
              grade: state.grade,
              subject: state.subject,
              timeLeft: state.timeLeftMinutes,
            );
          } else if (state is SOSFailure) {
            return _buildError(context, state.message);
          }
          return _buildLoading();
        },
      ),
      bottomNavigationBar: BlocBuilder<SOSBloc, SOSState>(
        builder: (context, state) {
          if (state is SOSSuccess) {
            return _buildBottomBar(context);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: BlocBuilder<SOSBloc, SOSState>(
        builder: (context, state) {
          final count = state is SOSSuccess ? state.strategies.length : 0;
          return Text(
            '$count Strategies for You',
            style: AppTextStyles.titleLarge,
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            context.read<SOSBloc>().add(const SOSRefreshRequested());
          },
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded),
          onPressed: () {
            // TODO: Read strategies aloud
          },
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            'Finding strategies...',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing your classroom context',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.sos,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SOSBloc>().add(const SOSRefreshRequested());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<SOSBloc>().add(const SOSRefreshRequested());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Different Strategies'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context
                    .read<SOSBloc>()
                    .add(const SOSSaveAllStrategiesRequested());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Strategies saved to your Shared Feed! Good luck! 💪')),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("I'll Try These"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SOSContent extends StatelessWidget {
  final List<Strategy> strategies;
  final List<YouTubeVideo> videos;
  final bool isOffline;
  final String? errorMessage;
  final String query;
  final String grade;
  final String subject;
  final int timeLeft;

  const _SOSContent({
    required this.strategies,
    required this.videos,
    required this.isOffline,
    this.errorMessage,
    required this.query,
    required this.grade,
    required this.subject,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Column(
          children: [
            Container(
              color: AppColors.surface,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Strategies'),
                  Tab(text: 'Videos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _StrategiesTab(
                    strategies: strategies,
                    isOffline: isOffline,
                    errorMessage: errorMessage,
                    query: query,
                    grade: grade,
                    subject: subject,
                    timeLeft: timeLeft,
                    onVideoTap: () {
                      DefaultTabController.of(context).animateTo(1);
                    },
                  ),
                  _VideosTab(videos: videos),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StrategiesTab extends StatelessWidget {
  final List<Strategy> strategies;
  final bool isOffline;
  final String? errorMessage;
  final String query;
  final String grade;
  final String subject;
  final int timeLeft;
  final VoidCallback onVideoTap;

  const _StrategiesTab({
    required this.strategies,
    required this.isOffline,
    this.errorMessage,
    required this.query,
    required this.grade,
    required this.subject,
    required this.timeLeft,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        // Offline/Error Banner
        if (isOffline || errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage ?? 'Using cached strategies (offline mode)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

        // Context Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$grade | $subject | ${query.length > 30 ? '${query.substring(0, 30)}...' : query}',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$timeLeft min',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

        const SizedBox(height: AppConstants.spacingMd),

        // Strategies
        for (int i = 0; i < strategies.length; i++) ...[
          _StrategyCard(
            strategy: strategies[i],
            index: i + 1,
            onVideoTap: onVideoTap,
          )
              .animate()
              .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: 100 * (i + 1)))
              .slideX(begin: 0.1, end: 0),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _VideosTab extends StatelessWidget {
  final List<YouTubeVideo> videos;

  const _VideosTab({required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No videos found for this topic',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppConstants.spacingMd,
        mainAxisSpacing: AppConstants.spacingMd,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _VideoCard(video: videos[index]).animate().fadeIn(
            duration: 300.ms, delay: Duration(milliseconds: 50 * index));
      },
    );
  }
}

class _StrategyCard extends StatefulWidget {
  final Strategy strategy;
  final int index;
  final VoidCallback onVideoTap;

  const _StrategyCard({
    required this.strategy,
    required this.index,
    required this.onVideoTap,
  });

  @override
  State<_StrategyCard> createState() => _StrategyCardState();
}

class _StrategyCardState extends State<_StrategyCard> {
  // Removed local _isSaved to use BLoC state source of truth

  @override
  Widget build(BuildContext context) {
    // Watch BLoC state for changes
    final sosState = context.watch<SOSBloc>().state;
    final isSaved = sosState is SOSSuccess &&
        sosState.savedStrategyMap.containsKey(widget.strategy.id);

    final difficultyColor = widget.strategy.difficulty == 'easy'
        ? AppColors.success
        : widget.strategy.difficulty == 'medium'
            ? AppColors.warning
            : AppColors.sos;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMd),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.strategy.emoji ?? '📚',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.strategy.title,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (widget.strategy.titleHi != null)
                        Text(
                          widget.strategy.titleHi!,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Time & Difficulty
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingXs,
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.strategy.timeMinutes} min',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.strategy.difficulty == 'easy'
                            ? Icons.sentiment_satisfied_rounded
                            : Icons.sentiment_neutral_rounded,
                        size: 14,
                        color: difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.strategy.difficulty.toUpperCase(),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: difficultyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Steps
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Steps:',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: 8),
                ...widget.strategy.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTextStyles.labelSmall,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTextStyles.strategyStep,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppConstants.radiusMd),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.strategy.ncfAlignment ?? 'NCF aligned',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.strategy.successCount} teachers used this',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onVideoTap,
                    icon:
                        const Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            _StrategyDetailsSheet(strategy: widget.strategy),
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isSaved) {
                        context.read<SOSBloc>().add(
                            SOSUnsaveStrategyRequested(widget.strategy.id));
                      } else {
                        context
                            .read<SOSBloc>()
                            .add(SOSSaveStrategyRequested(widget.strategy));
                      }
                    },
                    icon: Icon(
                        isSaved
                            ? Icons.bookmark_added
                            : Icons.bookmark_add_outlined,
                        size: 18),
                    label: Text(isSaved ? 'Saved' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: isSaved ? AppColors.success : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyDetailsSheet extends StatelessWidget {
  final Strategy strategy;

  const _StrategyDetailsSheet({required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                Text(
                  strategy.title,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  strategy.titleHi ?? '',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Divider(height: 32),
                _buildSection(
                    '🧱 Materials Needed', strategy.materials ?? ['None']),
                const SizedBox(height: 24),
                _buildSection('📝 Step-by-Step Instructions', strategy.steps),
                const SizedBox(height: 24),
                Text(
                  '🎯 NCF Alignment',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    strategy.ncfAlignment ?? 'Aligned with NCF 2023 guidelines',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.success),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child:
                        Icon(Icons.circle, size: 6, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final YouTubeVideo video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show video in bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _VideoPlayerBottomSheet(video: video),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusSm),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      video.thumbnail ?? 'https://via.placeholder.com/200x90',
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                            child: Icon(Icons.play_circle_outline)),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: AppTextStyles.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.channel,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for playing YouTube videos inline
class _VideoPlayerBottomSheet extends StatefulWidget {
  final YouTubeVideo video;

  const _VideoPlayerBottomSheet({required this.video});

  @override
  State<_VideoPlayerBottomSheet> createState() =>
      _VideoPlayerBottomSheetState();
}

class _VideoPlayerBottomSheetState extends State<_VideoPlayerBottomSheet> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.video.link) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'hi',
        forceHD: false,
        showLiveFullscreenButton: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });

      if (_isFullScreen) {
        // Enter fullscreen - push new route
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _FullScreenPlayer(
              controller: _controller,
              video: widget.video,
              onExitFullScreen: () {
                _controller.toggleFullScreenMode();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Video Player
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppColors.primary,
                progressColors: const ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: AppColors.primary,
                ),
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  FullScreenButton(),
                ],
              ),
            ),
          ),

          // Video Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.video.channel,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Fullscreen and Close buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _controller.toggleFullScreenMode();
                          },
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text('Full Screen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
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
  }
}

/// Fullscreen video player route
class _FullScreenPlayer extends StatelessWidget {
  final YoutubePlayerController controller;
  final YouTubeVideo video;
  final VoidCallback onExitFullScreen;

  const _FullScreenPlayer({
    required this.controller,
    required this.video,
    required this.onExitFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppColors.primary,
                progressColors: const ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: AppColors.primary,
                ),
              ),
            ),
            // Exit fullscreen button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: onExitFullScreen,
                icon: const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
