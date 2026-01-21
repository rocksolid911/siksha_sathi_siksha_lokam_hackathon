import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../settings/presentation/bloc/language_cubit.dart';
import 'widgets/edit_profile_dialog.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(const ProfileLoadRequested()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is ProfileDeleted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is ProfileLoaded) {
            final profileLang = state.profile.preferredLanguage;
            final currentLang =
                context.read<LanguageCubit>().state.languageCode;
            if (profileLang != currentLang) {
              context.read<LanguageCubit>().changeLanguage(Locale(profileLang));
            }
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Card
                      _buildProfileHeader(context, profile),
                      const SizedBox(height: AppConstants.spacingLg),

                      // Personal Information Card
                      _buildInfoCard(
                        context,
                        title:
                            AppLocalizations.of(context)!.personalInformation,
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF059669),
                        items: [
                          _InfoItem(
                            icon: Icons.school_outlined,
                            label: AppLocalizations.of(context)!.school,
                            value: profile.school ?? '',
                          ),
                          _InfoItem(
                            icon: Icons.location_on_outlined,
                            label: AppLocalizations.of(context)!.district,
                            value: profile.district ?? '',
                          ),
                          _InfoItem(
                            icon: Icons.map_outlined,
                            label: AppLocalizations.of(context)!.state,
                            value: profile.state ?? '',
                          ),
                        ],
                        onEdit: () => _showEditDialog(context, profile),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      // Teaching Details Card
                      _buildInfoCard(
                        context,
                        title: AppLocalizations.of(context)!.teachingDetails,
                        icon: Icons.class_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        items: [
                          _InfoItem(
                            icon: Icons.class_outlined,
                            label: AppLocalizations.of(context)!.gradesTaught,
                            value: profile.gradesDisplay,
                          ),
                          _InfoItem(
                            icon: Icons.book_outlined,
                            label: AppLocalizations.of(context)!.subjects,
                            value: profile.subjectsDisplay,
                          ),
                          _InfoItem(
                            icon: Icons.groups_outlined,
                            label: AppLocalizations.of(context)!.totalStudents,
                            value: '${profile.numberOfStudents}',
                          ),
                        ],
                        onEdit: () => _showEditDialog(context, profile),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      // App Settings Card
                      _buildSettingsCard(context),
                      const SizedBox(height: AppConstants.spacingLg),

                      // Action Buttons
                      _buildActionButtons(context),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            );
          }

          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          // Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_InfoItem> items,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          // Items
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                _buildInfoRow(entry.value),
                if (!isLast) const SizedBox(height: AppConstants.spacingSm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Row(
      children: [
        Icon(item.icon, size: 20, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                AppLocalizations.of(context)!.appSettings,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _buildLanguageSelector(context),
          const SizedBox(height: AppConstants.spacingSm),
          _buildNotificationSwitch(context),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, currentLocale) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Row(
            children: [
              const Icon(Icons.language, color: Color(0xFF6B7280), size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.preferredLanguage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: currentLocale.languageCode,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(AppLocalizations.of(context)!.english),
                  ),
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text(AppLocalizations.of(context)!.hindi),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    context
                        .read<LanguageCubit>()
                        .changeLanguage(Locale(newValue));

                    // Update backend profile
                    final profileState = context.read<ProfileBloc>().state;
                    if (profileState is ProfileLoaded) {
                      context.read<ProfileBloc>().add(
                            ProfileUpdateRequested(
                              profileState.profile.copyWith(
                                preferredLanguage: newValue,
                              ),
                            ),
                          );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSwitch(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = true;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingXxs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Color(0xFF6B7280), size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.enableNotifications,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() => isEnabled = value);
                },
                activeColor: const Color(0xFF059669),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(AppLocalizations.of(context)!.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                side: const BorderSide(color: Color(0xFF059669), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        // Delete Account Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: Text(AppLocalizations.of(context)!.deleteAccount),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, dynamic profile) {
    showDialog(
      context: context,
      builder: (ctx) => EditProfileDialog(
        profile: profile,
        onSave: (updatedProfile) {
          context.read<ProfileBloc>().add(
                ProfileUpdateRequested(updatedProfile),
              );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(AppLocalizations.of(context)!.logoutConfirmationTitle),
        content: Text(AppLocalizations.of(context)!.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<ProfileBloc>()
                  .add(const ProfileDeleteAccountRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
