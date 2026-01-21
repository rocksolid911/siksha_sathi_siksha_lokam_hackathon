import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import '../../../settings/presentation/bloc/language_cubit.dart';
import '../bloc/active_context_cubit.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _selectedGrade;
  String? _selectedSubject;
  String _selectedLanguage = 'en';

  List<String> _availableGrades = [];
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    // Initialize language from current cubit state
    final currentLang = context.read<LanguageCubit>().state.languageCode;
    _selectedLanguage = currentLang;
  }

  void _initializeOptions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.profile != null) {
      final profile = authState.profile!;

      // Parse Grades
      final gradesStr =
          profile['grades_taught'] ?? profile['gradesTaught'] ?? '';
      if (gradesStr.toString().isNotEmpty) {
        _availableGrades =
            gradesStr.toString().split(',').map((e) => e.trim()).toList();
      }

      // Parse Subjects
      final subjectsStr =
          profile['subjects_taught'] ?? profile['subjectsTaught'] ?? '';
      if (subjectsStr.toString().isNotEmpty) {
        _availableSubjects =
            subjectsStr.toString().split(',').map((e) => e.trim()).toList();
      }
    }

    // Fallbacks if empty
    if (_availableGrades.isEmpty) {
      _availableGrades = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
    }
    if (_availableSubjects.isEmpty) {
      _availableSubjects = [
        'Math',
        'Science',
        'English',
        'Hindi',
        'Social Science'
      ];
    }

    _selectedGrade = _availableGrades.first;
    _selectedSubject = _availableSubjects.first;
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring translations are available
    // Ensuring translations are available
    // final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Header
              Text(
                'Welcome to Shiksha Saathi',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s set up your preferences to get started.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Language Selection
              _buildDropdown<String>(
                label: 'Preferred Language', // TODO: Localize
                value: _selectedLanguage,
                items: [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    context.read<LanguageCubit>().changeLanguage(Locale(val));
                  }
                },
              ),
              const SizedBox(height: 24),

              // Grade Selection
              _buildDropdown<String>(
                label: 'Select Grade', // TODO: Localize
                value: _selectedGrade,
                items: _availableGrades
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('Grade $g'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGrade = val);
                },
              ),
              const SizedBox(height: 24),

              // Subject Selection
              _buildDropdown<String>(
                label: 'Select Subject', // TODO: Localize
                value: _selectedSubject,
                items: _availableSubjects
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),

              const Spacer(flex: 2),

              // Get Started Button
              FilledButton(
                onPressed: _handleGetStarted,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _handleGetStarted() async {
    if (_selectedGrade != null && _selectedSubject != null) {
      // Save to Cubit (which saves to disk)
      // We must await this to ensure state is updated before UI reacts
      // (though AuthWrapper reacts to stream, awaiting ensures persistence starts)
      await context.read<ActiveContextCubit>().updateContext(
            grade: _selectedGrade!,
            subject: _selectedSubject!,
          );

      // No need to navigate manually; AuthWrapper is listening to ActiveContextState
      // and will switch to HomeScreen when isInitialized becomes true.
    }
  }
}
