import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/sos_fab.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import 'widgets/context_card.dart';
import 'widgets/quick_actions.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../library/presentation/screens/library_screen.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../search/presentation/screens/search_screen.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';
import '../../learn/data/repositories/learn_repository.dart';
import '../../learn/presentation/screens/strategy_detail_screen.dart';

import '../../context/presentation/bloc/active_context_cubit.dart';
import '../../context/presentation/bloc/active_context_state.dart';

/// Home Dashboard Screen
/// Main screen of the app with context, quick actions, and challenges
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService().initUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveContextCubit, ActiveContextState>(
      listener: (context, state) {
        // Optional: Listen for side effects if needed
      },
      builder: (context, activeContextState) {
        // Use active context from cubit
        final activeGrade = activeContextState.activeGrade ?? '';
        final activeSubject = activeContextState.activeSubject ?? '';

        // We still need available options to be passed to ContextCard
        // For now, we can parse them here or in the Cubit.
        // Let's parse them here from AuthBloc for now to keep it simple,
        // as ActiveContextCubit only stores the *selection*.

        final authState = context.read<AuthBloc>().state;
        List<String> availableGrades = [];
        List<String> availableSubjects = [];
        // Student Count
        int studentCount = 35; // Default

        // Priority 1: Active Context (User manually set this session/persisted)
        if (activeContextState.studentCount != null) {
          studentCount = activeContextState.studentCount!;
        }
        // Priority 2: Profile (User's default setting)
        else if (authState is AuthAuthenticated && authState.profile != null) {
          final profile = authState.profile!;
          final count =
              profile['number_of_students'] ?? profile['numberOfStudents'];
          if (count != null) {
            studentCount =
                count is int ? count : int.tryParse(count.toString()) ?? 35;
          }
        }

        // Parse Grades & Subjects from profile for options
        if (authState is AuthAuthenticated && authState.profile != null) {
          final profile = authState.profile!;
          // Parse Grades
          final gradesStr =
              profile['grades_taught'] ?? profile['gradesTaught'] ?? '';
          if (gradesStr.toString().isNotEmpty) {
            availableGrades =
                gradesStr.toString().split(',').map((e) => e.trim()).toList();
          }
          // Parse Subjects
          final subjectsStr =
              profile['subjects_taught'] ?? profile['subjectsTaught'] ?? '';
          if (subjectsStr.toString().isNotEmpty) {
            availableSubjects =
                subjectsStr.toString().split(',').map((e) => e.trim()).toList();
          }
        }

        // Fallbacks
        if (availableGrades.isEmpty) {
          availableGrades = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
        }
        if (availableSubjects.isEmpty) {
          availableSubjects = [
            'Math',
            'Science',
            'English',
            'Hindi',
            'Social Science'
          ];
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Main content
              SafeArea(
                bottom: false, // Allow content to go behind bottom nav
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildBody(
                        activeGrade,
                        activeSubject,
                        studentCount,
                        availableGrades,
                        availableSubjects,
                      ),
                    ),
                  ],
                ),
              ),
              // Floating bottom navigation
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80), // Lift above nav bar
            child: SOSFloatingButton(
              activeGrade: activeGrade,
              activeSubject: activeSubject,
              studentCount: studentCount,
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  // Removed _initializeContext and local state variables

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.appName,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationScreen()),
              );
            },
            child: StreamBuilder<int>(
              stream: NotificationService().unreadCount,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  Widget _buildBody(
    String activeGrade,
    String activeSubject,
    int studentCount,
    List<String> availableGrades,
    List<String> availableSubjects,
  ) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(
          activeGrade,
          activeSubject,
          studentCount,
          availableGrades,
          availableSubjects,
        );
      case 1:
        // Lazy load library
        return const LibraryScreen();
      case 2:
        // Lazy load search
        return const SearchScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent(
          activeGrade,
          activeSubject,
          studentCount,
          availableGrades,
          availableSubjects,
        );
    }
  }

  Widget _buildHomeContent(
    String activeGrade,
    String activeSubject,
    int studentCount,
    List<String> availableGrades,
    List<String> availableSubjects,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Card
          ContextCard(
            activeGrade: activeGrade,
            activeSubject: activeSubject,
            studentCount: studentCount,
            availableGrades: availableGrades,
            availableSubjects: availableSubjects,
            onContextUpdate: (grade, subject, count) {
              // Update via Cubit
              context.read<ActiveContextCubit>().updateContext(
                  grade: grade, subject: subject, studentCount: count);
            },
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: AppConstants.spacingLg),

          // Quick Actions
          QuickActionsGrid(
            activeGrade: activeGrade,
            activeSubject: activeSubject,
            studentCount: studentCount,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: AppConstants.spacingLg),

          // Trending
          _buildTrendingSection(activeGrade, activeSubject)
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.1, end: 0),

          // Bottom padding for FAB and floating nav bar
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(String activeGrade, String activeSubject) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Trending This Week',
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        FutureBuilder<List<dynamic>>(
          future: context.read<LearnRepository>().getTrending(
                grade: activeGrade,
                subject: activeSubject,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Could not load trending: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No trending strategies yet.');
            }

            final items = snapshot.data!;
            // Show top 3
            return Column(
              children: items
                  .take(3)
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildTrendingCard(item),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingCard(dynamic item) {
    // Use camera icon for all trending cards
    const IconData cardIcon = Icons.camera_alt_outlined;
    const Color iconBgColor = Color(0xFFEDE9FE); // Light purple
    const Color iconColor = Color(0xFF7C3AED); // Purple

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StrategyDetailScreen(item: item),
          ),
        );
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
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (item.titleHi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.titleHi!,
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
                          item.subject?.toUpperCase() ?? 'SUBJECT',
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
                          'CLASS ${item.grade}',
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
              onPressed: () {
                // TODO: Implement delete functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Delete functionality coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(
            // Dynamically set primary color based on selected index
            primaryColor: [
              const Color(0xFF059669), // Green for Home
              const Color(0xFF3B82F6), // Blue for Library
              const Color(0xFF8B5CF6), // Purple for Search
              const Color(0xFFF97316), // Orange for Profile
            ][_currentIndex],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedItemColor: [
              const Color(0xFF059669), // Green for Home
              const Color(0xFF3B82F6), // Blue for Library
              const Color(0xFF8B5CF6), // Purple for Search
              const Color(0xFFF97316), // Orange for Profile
            ][_currentIndex],
            unselectedItemColor: const Color(0xFF9CA3AF),
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_rounded,
                  color: _currentIndex == 0
                      ? const Color(0xFF059669)
                      : const Color(0xFF9CA3AF),
                ),
                label: AppLocalizations.of(context)!.home,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.library_books_rounded,
                  color: _currentIndex == 1
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF9CA3AF),
                ),
                label: AppLocalizations.of(context)!.library,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.search_rounded,
                  color: _currentIndex == 2
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF9CA3AF),
                ),
                label: AppLocalizations.of(context)!.search,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_rounded,
                  color: _currentIndex == 3
                      ? const Color(0xFFF97316)
                      : const Color(0xFF9CA3AF),
                ),
                label: AppLocalizations.of(context)!.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
