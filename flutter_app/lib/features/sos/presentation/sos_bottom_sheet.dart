import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'sos_response_screen.dart';

/// SOS Bottom Sheet
/// Quick help interface for teachers in emergency
class SOSBottomSheet extends StatefulWidget {
  final String activeGrade;
  final String activeSubject;
  final int studentCount;
  final bool
      autoStartListening; // Auto-start speech when true (from Quick Actions)

  const SOSBottomSheet({
    super.key,
    this.activeGrade = '',
    this.activeSubject = '',
    this.studentCount = 35,
    this.autoStartListening = false, // Default: don't auto-start
  });

  @override
  State<SOSBottomSheet> createState() => _SOSBottomSheetState();
}

class _SOSBottomSheetState extends State<SOSBottomSheet> {
  final TextEditingController _queryController = TextEditingController();
  int _selectedTimeIndex = 1; // Default: 10 min
  bool _isLoading = false;

  // Temporary context (can be changed without persisting)
  late String _tempGrade;
  late String _tempSubject;
  late int _tempStudentCount;

  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    // Initialize temporary context from widget params
    _tempGrade = widget.activeGrade;
    _tempSubject = widget.activeSubject;
    _tempStudentCount = widget.studentCount;
    _initSpeech();
  }

  /// Initialize speech recognition and conditionally auto-start listening
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${error.errorMsg}')),
          );
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );

    // Only auto-start if explicitly requested (from Quick Actions)
    if (_speechEnabled && mounted && widget.autoStartListening) {
      await Future.delayed(const Duration(milliseconds: 500));
      _startListening();
    }
  }

  /// Start listening for speech input
  void _startListening() async {
    if (!_speechEnabled) return;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          _queryController.text = _lastWords;
          // Move cursor to end
          _queryController.selection = TextSelection.fromPosition(
            TextPosition(offset: _queryController.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_IN', // Indian English
      cancelOnError: true,
    );

    setState(() => _isListening = true);
  }

  /// Stop listening for speech input
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  /// Toggle listening state
  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _queryController.dispose();
    super.dispose();
  }

  void _submitQuery() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.describeProblem)),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Navigate to response screen which will handle the API call
    // Use temporary context values (may have been edited by user)
    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SOSResponseScreen(
            query: query,
            grade: _tempGrade.isNotEmpty ? _tempGrade : 'Class 4', // Fallback
            subject:
                _tempSubject.isNotEmpty ? _tempSubject : 'Math', // Fallback
            timeLeft: AppConstants.timeOptions[_selectedTimeIndex],
          ),
        ),
      );
    }

    // Reset loading state if we didn't navigate (though we pop above)
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  children: [
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildContextChips()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 50.ms),
                    const SizedBox(height: AppConstants.spacingLg),
                    _buildQueryInput()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms),
                    const SizedBox(height: AppConstants.spacingLg),
                    _buildTimeSelector()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 150.ms),
                    const SizedBox(height: AppConstants.spacingLg),
                    _buildSubmitButton()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 250.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppConstants.spacingMd),
                    _buildOfflineIndicator()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 300.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sosLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: AppColors.sos,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.sosQuickHelp,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.sos,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.getInstantStrategies,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.currentContext,
              style: AppTextStyles.titleMedium,
            ),
            TextButton.icon(
              onPressed: _showContextEditor,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
                _tempGrade.isEmpty
                    ? AppLocalizations.of(context)!.gradeNotSet
                    : '${AppLocalizations.of(context)!.classLabel} $_tempGrade',
                true),
            _buildChip(
                _tempSubject.isEmpty
                    ? AppLocalizations.of(context)!.subjectNotSet
                    : _tempSubject,
                true),
            _buildChip(
                '$_tempStudentCount ${AppLocalizations.of(context)!.students}',
                true),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Temporary for this query only',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Show dialog to edit context temporarily
  void _showContextEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Context'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grade/Class',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '10',
                    '11',
                    '12'
                  ]
                      .map((grade) => ChoiceChip(
                            label: Text('Class $grade'),
                            selected: _tempGrade == grade,
                            onSelected: (selected) {
                              setDialogState(() => _tempGrade = grade);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Subject',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['Math', 'Science', 'English', 'Hindi', 'Social Science']
                          .map((subject) => ChoiceChip(
                                label: Text(subject),
                                selected: _tempSubject == subject,
                                onSelected: (selected) {
                                  setDialogState(() => _tempSubject = subject);
                                },
                              ))
                          .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Student Count',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Slider(
                  value: _tempStudentCount.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '$_tempStudentCount students',
                  onChanged: (value) {
                    setDialogState(() => _tempStudentCount = value.toInt());
                  },
                ),
                Text('$_tempStudentCount students',
                    style: AppTextStyles.bodySmall),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Refresh to show new temp values
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.whatsHappening,
              style: AppTextStyles.titleMedium,
            ),
            if (_isListening) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sos.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sos,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 600.ms)
                        .then()
                        .fadeOut(duration: 600.ms),
                    const SizedBox(width: 6),
                    Text(
                      'Listening...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.sos,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _queryController,
          maxLines: 3,
          onChanged: (text) {
            // If user starts typing manually, stop listening
            if (_isListening && text != _lastWords) {
              _stopListening();
            }
          },
          decoration: InputDecoration(
            hintText: _isListening
                ? 'Speak now...'
                : AppLocalizations.of(context)!.micHint,
            hintMaxLines: 4,
            suffixIcon: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.sos
                      : (_speechEnabled
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              )
                  .animate(
                    target: _isListening ? 1 : 0,
                    onPlay: (controller) =>
                        _isListening ? controller.repeat() : null,
                  )
                  .scale(
                    duration: 1000.ms,
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                  )
                  .then()
                  .scale(
                    duration: 1000.ms,
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1.0, 1.0),
                  ),
              onPressed: _speechEnabled ? _toggleListening : null,
              tooltip: _isListening ? 'Stop listening' : 'Start listening',
            ),
          ),
        ),
        if (!_speechEnabled && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Voice input not available. Please type your problem.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timeLeft,
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < AppConstants.timeOptions.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTimeIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTimeIndex == i
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                      border: _selectedTimeIndex == i
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${AppConstants.timeOptions[i]}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: _selectedTimeIndex == i
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.minutes,
                          style: AppTextStyles.caption.copyWith(
                            color: _selectedTimeIndex == i
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < AppConstants.timeOptions.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitQuery,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sos,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.getHelpNow,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.worksOffline,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
