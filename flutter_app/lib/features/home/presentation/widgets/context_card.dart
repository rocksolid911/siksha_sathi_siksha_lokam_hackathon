import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

/// Context Card Widget - Redesigned to match new UI
/// Shows the teacher's active classroom context with pill-style chips
class ContextCard extends StatelessWidget {
  final String activeGrade;
  final String activeSubject;
  final int studentCount;
  final List<String> availableGrades;
  final List<String> availableSubjects;
  final Function(String grade, String subject, int count) onContextUpdate;

  const ContextCard({
    super.key,
    required this.activeGrade,
    required this.activeSubject,
    required this.studentCount,
    required this.availableGrades,
    required this.availableSubjects,
    required this.onContextUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.push_pin,
                color: Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Active Context',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showEditContextDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPillChip(
                label: 'Class $activeGrade',
                icon: Icons.school,
                backgroundColor: const Color(0xFFE8F5E9),
                textColor: const Color(0xFF2E7D32),
                iconColor: const Color(0xFF2E7D32),
              ),
              _buildPillChip(
                label: activeSubject,
                icon: Icons.science,
                backgroundColor: const Color(0xFFE3F2FD),
                textColor: const Color(0xFF1565C0),
                iconColor: const Color(0xFF1565C0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStudentCount(),
        ],
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.check_circle, size: 16, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildStudentCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$studentCount Students',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditContextDialog(BuildContext context) {
    String selectedGrade = activeGrade;
    String selectedSubject = activeSubject;
    final TextEditingController countController =
        TextEditingController(text: studentCount.toString());

    // Ensure we have lists
    final safeGrades =
        availableGrades.isNotEmpty ? availableGrades : ['4', '5', '6'];
    final safeSubjects =
        availableSubjects.isNotEmpty ? availableSubjects : ['Math', 'Science'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.updateContext),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value:
                      safeGrades.contains(selectedGrade) ? selectedGrade : null,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.grade),
                  items: safeGrades.map((g) {
                    return DropdownMenuItem(
                        value: g,
                        child: Text(
                            '${AppLocalizations.of(context)!.classLabel} $g'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedGrade = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: safeSubjects.contains(selectedSubject)
                      ? selectedSubject
                      : null,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.subject),
                  items: safeSubjects.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedSubject = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.numberOfStudents),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                onContextUpdate(
                  selectedGrade,
                  selectedSubject,
                  int.tryParse(countController.text) ?? studentCount,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
