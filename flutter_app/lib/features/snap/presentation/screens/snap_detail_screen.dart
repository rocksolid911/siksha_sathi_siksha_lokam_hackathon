import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';

class SnapDetailScreen extends StatelessWidget {
  final Map<String, dynamic> snapData;

  const SnapDetailScreen({Key? key, required this.snapData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final String question =
        snapData['text'] ?? snapData['question'] ?? 'No Question Text';
    final Map<String, dynamic> solutionData = snapData['solution'] is Map
        ? snapData['solution']
        : {'solution_markdown': 'No solution data available'};
    final String solutionMarkdown =
        solutionData['solution_markdown'] ?? 'No solution content';

    // Metadata
    final String subject = snapData['subject'] ?? 'General';
    final String grade = snapData['grade'] ?? 'Unknown Class';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap Solution'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                'Check out this solution from Shiksha Saathi:\n\nCreate Question: $question\n\nSolution:\n$solutionMarkdown',
                subject: 'Snap Solution: $subject',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata Card
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppTheme.lightTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '$grade • $subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question Section
            const Text(
              'Question',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                question,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Answer Section
            const Text(
              'Solution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: solutionMarkdown,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  p: const TextStyle(fontSize: 15, height: 1.5),
                  code: TextStyle(
                    backgroundColor: Colors.grey.shade100,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Check out this solution from Shiksha Saathi:\n\nQ: $question\n\nSolution:\n$solutionMarkdown',
                        subject: 'Snap Solution: $subject',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Already saved if viewed from Library, but if from notification it might be transient?
                      // The notification flow says "Solution will be saved to your Library", so it is likely already saved.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Solution is already saved in your Library')),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Saved'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
