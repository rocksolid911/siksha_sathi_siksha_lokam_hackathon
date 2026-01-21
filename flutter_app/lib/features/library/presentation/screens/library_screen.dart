import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shiksha_saathi/core/constants/app_colors.dart';
import 'package:shiksha_saathi/core/constants/app_constants.dart';
import 'package:shiksha_saathi/core/constants/app_text_styles.dart';
import 'package:shiksha_saathi/features/library/data/library_repository.dart';
import 'package:shiksha_saathi/features/library/presentation/widgets/resource_card.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';
import '../screens/saved_strategy_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LibraryRepository _repository = LibraryRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.libraryTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primary,
          labelStyle:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.savedStrategies),
            const Tab(text: 'Snaps'), // Localize later if needed
            Tab(text: AppLocalizations.of(context)!.resources),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedStrategies(),
          _buildSavedSnaps(),
          _buildResources(),
        ],
      ),
    );
  }

  Widget _buildSavedStrategies() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _repository.getSavedStrategies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bookmark,
                    size: 64, color: AppColors.neutral300),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noSavedStrategies,
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          );
        }

        final strategies = snapshot.data!
            .where((s) => s['type'] == 'strategy' || s['type'] == null)
            .toList();

        if (strategies.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noSavedStrategies,
                style: AppTextStyles.bodyLarge),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: strategies.length,
            itemBuilder: (context, index) {
              final strategy = strategies[index];
              final strategyId = strategy['id'];

              // Get subject configuration from constants
              final config = AppConstants.getSubjectConfig(strategy['subject']);
              final iconBgColor = Color(config['iconBgColor']);
              final iconColor = Color(config['iconColor']);
              final cardIcon = _getIconData(config['icon']);

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedStrategyDetailScreen(
                        strategy: strategy,
                        onDelete: () => _handleDelete(strategyId),
                      ),
                    ),
                  );
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cardIcon,
                          color: iconColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strategy['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            if (strategy['title_hi'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                strategy['title_hi'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Subject badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (strategy['subject'] ?? 'GENERAL')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Class badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFED7AA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CLASS ${strategy['grade'] ?? 'ALL'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Delete icon
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        onPressed: () => _confirmDelete(strategyId),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedSnaps() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _repository.getSavedStrategies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No snaps saved yet"));
        }

        final snaps = snapshot.data!.where((s) => s['type'] == 'snap').toList();

        if (snaps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.camera, size: 64, color: AppColors.neutral300),
                const SizedBox(height: 16),
                Text(
                  'No saved snaps',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snaps.length,
            itemBuilder: (context, index) {
              final snap = snaps[index];
              final snapId = snap['id'];

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedStrategyDetailScreen(
                        strategy: snap,
                        onDelete: () => _handleDelete(snapId),
                      ),
                    ),
                  );
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Camera icon circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE), // Light purple
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF7C3AED), // Purple
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snap['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Subject badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (snap['subject'] ?? 'GENERAL')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Class badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFED7AA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CLASS ${snap['grade'] ?? 'ALL'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Delete icon
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        onPressed: () => _confirmDelete(snapId),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildResources() {
    final resources = _repository.getStaticResources();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        IconData icon;
        switch (resource['icon']) {
          case 'book_open':
            icon = LucideIcons.bookOpen;
            break;
          case 'shapes':
            icon = LucideIcons.shapes;
            break;
          case 'target':
            icon = LucideIcons.target;
            break;
          default:
            icon = LucideIcons.fileText;
        }

        return ResourceCard(
          title: resource['title'],
          subtitle: resource['subtitle'],
          type: resource['type'],
          iconResult: icon,
          color: resource['color'],
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${AppLocalizations.of(context)!.pdfViewer} coming soon...')),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDelete(int id) async {
    final success = await _repository.deleteSavedStrategy(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.strategyRemoved)),
        );
        setState(() {}); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemove)),
        );
      }
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFromLibraryTitle),
        content: Text(AppLocalizations.of(context)!.removeFromLibraryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(id);
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// Helper method to convert icon string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calculate_outlined':
        return Icons.calculate_outlined;
      case 'science_outlined':
        return Icons.science_outlined;
      case 'menu_book_outlined':
        return Icons.menu_book_outlined;
      case 'translate_outlined':
        return Icons.translate_outlined;
      case 'public_outlined':
        return Icons.public_outlined;
      case 'computer_outlined':
        return Icons.computer_outlined;
      case 'sports_outlined':
        return Icons.sports_outlined;
      case 'palette_outlined':
        return Icons.palette_outlined;
      case 'music_note_outlined':
        return Icons.music_note_outlined;
      case 'lightbulb_outline_rounded':
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
