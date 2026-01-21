import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shiksha_saathi/features/context/presentation/bloc/active_context_cubit.dart';
import 'package:shiksha_saathi/features/snap/bloc/snap_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';

class SnapScreen extends StatelessWidget {
  const SnapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SnapBloc(),
      child: const SnapScreenView(),
    );
  }
}

class SnapScreenView extends StatefulWidget {
  const SnapScreenView({Key? key}) : super(key: key);

  @override
  State<SnapScreenView> createState() => _SnapScreenViewState();
}

class _SnapScreenViewState extends State<SnapScreenView> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap & Solve'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SnapBloc>().add(SnapReset());
              _textController.clear();
            },
          )
        ],
      ),
      body: BlocConsumer<SnapBloc, SnapState>(
        listener: (context, state) {
          if (state is SnapError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is SnapOfflineQueued) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Text('You are offline'),
                  ],
                ),
                content: const Text(
                    'No internet connection. Your request has been queued and will be processed automatically when you are back online.\n\n✓ Solution will be saved to your Library\n✓ You\'ll receive a notification when ready'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is SnapScanned) {
            _textController.text = state.extractedText;
          } else if (state is SnapSolutionLoaded) {
            if (state.saveStatus == SaveStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Solution saved to Library!'),
                    backgroundColor: Colors.green),
              );
            } else if (state.saveStatus == SaveStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Failed to save solution'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Image Capture/Preview Area
                if (state is SnapInitial)
                  _buildCaptureArea(context)
                else
                  _buildImagePreview(context, state),

                const SizedBox(height: 20),

                // 2. Editor Area
                if (state is SnapScanning)
                  const Center(child: CircularProgressIndicator())
                else if (state is SnapScanned ||
                    state is SnapSolutionLoading ||
                    state is SnapSolutionLoaded ||
                    state is SnapOfflineQueued ||
                    (state is SnapError && state is! SnapInitial))
                  // Show editor if we have scanned text or are in error state after scanning
                  if (state is SnapScanned ||
                      state is SnapSolutionLoading ||
                      state is SnapSolutionLoaded ||
                      state is SnapOfflineQueued ||
                      (state is SnapError &&
                          state is! SnapInitial &&
                          state.imageFile != null)) // correct check
                    _buildEditorArea(context, state),

                const SizedBox(height: 20),

                // 3. Solution Area
                if (state is SnapSolutionLoading)
                  _buildLoadingSolution()
                else if (state is SnapSolutionLoaded)
                  _buildSolutionView(context, state),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<SnapBloc, SnapState>(
        builder: (context, state) {
          if (state is SnapInitial) {
            return FloatingActionButton.extended(
              onPressed: () => context
                  .read<SnapBloc>()
                  .add(const SnapImagePicked(ImageSource.camera)),
              label: const Text('Take Photo'),
              icon: const Icon(Icons.camera_alt),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCaptureArea(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_enhance, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'Take a photo of a doubt or problem',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<SnapBloc>()
                      .add(const SnapImagePicked(ImageSource.camera)),
                  icon: const Icon(Icons.camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<SnapBloc>()
                      .add(const SnapImagePicked(ImageSource.gallery)),
                  icon: const Icon(Icons.image),
                  label: const Text('Gallery'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, SnapState state) {
    File? imageFile;
    if (state is SnapScanning) imageFile = state.imageFile;
    if (state is SnapScanned) imageFile = state.imageFile;
    if (state is SnapSolutionLoading) imageFile = state.imageFile;
    if (state is SnapSolutionLoaded) imageFile = state.imageFile;
    if (state is SnapError) imageFile = state.imageFile;
    if (state is SnapOfflineQueued) imageFile = state.imageFile;

    if (imageFile == null) return const SizedBox.shrink();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(imageFile,
              height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildEditorArea(BuildContext context, SnapState state) {
    final bool isSolving = state is SnapSolutionLoading;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Extracted Question:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              enabled: !isSolving,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Edit text if OCR made mistakes...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSolving
                    ? null
                    : () {
                        final contextState =
                            context.read<ActiveContextCubit>().state;
                        context.read<SnapBloc>().add(SnapSolveRequested(
                              text: _textController.text,
                              grade: contextState.activeGrade ?? '',
                              subject: contextState.activeSubject ?? '',
                            ));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: isSolving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(isSolving ? 'Solving...' : 'Get AI Solution'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSolution() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 150, color: Colors.white),
          const SizedBox(height: 10),
          Container(height: 100, width: double.infinity, color: Colors.white),
          const SizedBox(height: 10),
          Container(height: 100, width: double.infinity, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSolutionView(BuildContext context, SnapSolutionLoaded state) {
    final solutionMarkdown =
        state.solution['solution_markdown'] ?? 'No solution generated';
    final isSaving = state.saveStatus == SaveStatus.saving;
    final isSaved = state.saveStatus == SaveStatus.success;

    // Get metadata from state or active context
    final contextState = context.read<ActiveContextCubit>().state;
    final subject = contextState.activeSubject ?? 'General';
    final grade = contextState.activeGrade ?? 'Unknown Class';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solution',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.primaryColor),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(
                        'Check out this solution from Shiksha Saathi ($grade - $subject):\n\n$solutionMarkdown',
                        subject: 'Snap & Solve Solution');
                  },
                  tooltip: 'Share Solution',
                ),
                IconButton(
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  color: isSaved ? AppTheme.lightTheme.primaryColor : null,
                  onPressed: (isSaving || isSaved)
                      ? null
                      : () {
                          context.read<SnapBloc>().add(SnapSaveRequested(
                                title:
                                    "Snap Solution ${DateTime.now().toString().substring(0, 16)}", // Default title
                                content: solutionMarkdown,
                                subject: subject,
                                grade: grade,
                              ));
                        },
                  tooltip: 'Save to Library',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Metadata Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school,
                  size: 16, color: AppTheme.lightTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '$grade • $subject',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: MarkdownBody(
            data: solutionMarkdown,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
