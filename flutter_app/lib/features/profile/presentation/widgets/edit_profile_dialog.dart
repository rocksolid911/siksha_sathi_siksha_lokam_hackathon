import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/teacher_profile_model.dart';

class EditProfileDialog extends StatefulWidget {
  final TeacherProfile profile;
  final Function(TeacherProfile) onSave;

  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _gradesController;
  late TextEditingController _subjectsController;
  late TextEditingController _studentsController;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _schoolController = TextEditingController(text: widget.profile.school);
    _districtController = TextEditingController(text: widget.profile.district);
    _stateController = TextEditingController(text: widget.profile.state);
    _gradesController =
        TextEditingController(text: widget.profile.gradesTaught);
    _subjectsController =
        TextEditingController(text: widget.profile.subjectsTaught);
    _studentsController = TextEditingController(
      text: widget.profile.numberOfStudents.toString(),
    );
    _selectedLanguage = widget.profile.preferredLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _gradesController.dispose();
    _subjectsController.dispose();
    _studentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _schoolController,
                  label: 'School Name',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _districtController,
                        label: 'District',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        label: 'State',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Teaching Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _gradesController,
                  label: 'Grades Taught (e.g. 5, 6, 7)',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _subjectsController,
                  label: 'Subjects Taught',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _studentsController,
                  label: 'Total Students',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Language Selection
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: 'Preferred Language',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() == true) {
      final updatedProfile = widget.profile.copyWith(
        name: _nameController.text.trim(),
        school: _schoolController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        gradesTaught: _gradesController.text.trim(),
        subjectsTaught: _subjectsController.text.trim(),
        numberOfStudents: int.tryParse(_studentsController.text.trim()) ?? 0,
        preferredLanguage: _selectedLanguage,
      );
      widget.onSave(updatedProfile);
      Navigator.of(context).pop();
    }
  }
}
