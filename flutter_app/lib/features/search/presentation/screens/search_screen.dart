import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shiksha_saathi/core/constants/app_colors.dart';
import 'package:shiksha_saathi/core/constants/app_text_styles.dart';
import 'package:shiksha_saathi/features/search/bloc/search_bloc.dart';
import 'package:shiksha_saathi/features/search/bloc/search_event.dart';
import 'package:shiksha_saathi/features/search/bloc/search_state.dart';
import 'package:shiksha_saathi/features/search/presentation/widgets/search_filter_chip.dart';
import 'package:shiksha_saathi/features/search/presentation/widgets/video_result_card.dart';
import 'package:shiksha_saathi/features/search/presentation/screens/video_player_screen.dart';
import 'package:shiksha_saathi/features/profile/bloc/profile_bloc.dart';
import 'package:shiksha_saathi/features/profile/bloc/profile_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            final activeFilter =
                state is SearchSuccess ? state.activeFilter : 'All';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    AppLocalizations.of(context)!.searchTitle,
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: const Icon(LucideIcons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchBloc>().add(const SearchReset());
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.neutral100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (query) {
                      if (query.trim().isEmpty) return;

                      String enrichedQuery = query;
                      try {
                        final profileState = context.read<ProfileBloc>().state;
                        if (profileState is ProfileLoaded) {
                          final p = profileState.profile;
                          final parts = <String>[];

                          // Add Class/Grade context
                          if (p.gradesTaught != null &&
                              p.gradesTaught!.isNotEmpty) {
                            parts.add('Class ${p.gradesTaught}');
                          }

                          // Add Subject context
                          if (p.subjectsTaught != null &&
                              p.subjectsTaught!.isNotEmpty) {
                            parts.add(p.subjectsTaught!);
                          }

                          if (parts.isNotEmpty) {
                            enrichedQuery += ' ${parts.join(' ')}';
                          }
                        }
                      } catch (_) {
                        // Look up failed (Provider not found or other error), continue with basic query
                      }

                      context
                          .read<SearchBloc>()
                          .add(SearchQueryChanged(enrichedQuery));
                    },
                  ),
                ),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AppLocalizations.of(context)!.all,
                      AppLocalizations.of(context)!.videos,
                      AppLocalizations.of(context)!.pdfs
                    ].map((filter) {
                      return SearchFilterChip(
                        label: filter,
                        isSelected: activeFilter == filter,
                        onTap: () {
                          context
                              .read<SearchBloc>()
                              .add(SearchFilterChanged(filter));
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Content based on state
                Expanded(
                  child: _buildContent(state, activeFilter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(SearchState state, String activeFilter) {
    if (state is SearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SearchFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.searchFailed,
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
      );
    }

    if (state is SearchSuccess) {
      if (state.results.isEmpty) {
        return _buildEmptyState(
            '${AppLocalizations.of(context)!.noResults} "${state.query}"');
      }

      // Filter results on UI side for responsiveness in this simple case
      // Or rely on Bloc state to filter. Bloc state holds ALL results.
      // We filter display list here.
      final filteredResults = state.results.where((result) {
        if (activeFilter == AppLocalizations.of(context)!.all) return true;
        if (activeFilter == AppLocalizations.of(context)!.videos)
          return result['type'] == 'video';
        if (activeFilter == AppLocalizations.of(context)!.pdfs)
          return result['type'] == 'pdf';
        return true;
      }).toList();

      if (filteredResults.isEmpty) {
        return _buildEmptyState(
            '${AppLocalizations.of(context)!.noResults} ($activeFilter)');
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredResults.length,
        itemBuilder: (context, index) {
          final result = filteredResults[index];
          if (result['type'] == 'video') {
            return VideoResultCard(
              video: result,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      videoId: result['videoId'],
                      title: result['title'],
                    ),
                  ),
                );
              },
            );
          } else {
            return _buildPdfCard(result);
          }
        },
      );
    }

    // Initial State
    return _buildEmptyState(AppLocalizations.of(context)!.searchHint);
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 64, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text(
            message,
            style:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(Map<String, dynamic> result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: () async {
          final url = Uri.parse(result['link']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.couldNotOpenPdf)),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.fileText, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['title'],
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result['subtitle'] ?? 'PDF Resource',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.neutral500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.tapToOpen,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.externalLink,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
