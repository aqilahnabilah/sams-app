// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/course_service.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();

  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _lecturerController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();
      final lecturer = _lecturerController.text.trim();
      final section = _sectionController.text.trim();
      final capacity = int.parse(_capacityController.text.trim());

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      await _courseService.addSubject(
        code: code,
        name: name,
        lecturer: lecturer,
        section: section,
        capacity: capacity,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('Subject $code added successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
      navigator.pop(); // Go back to the main course page
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1C2C),
              Color(0xFF928DAB),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add New Subject',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Card Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Course Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Subject Code
                          TextFormField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Subject Code (e.g. CSE3201)',
                              icon: Icons.code,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter subject code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Subject Name
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Subject Name',
                              icon: Icons.menu_book,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter subject name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Lecturer Name
                          TextFormField(
                            controller: _lecturerController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Lecturer Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter lecturer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Section and Capacity Rows
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: _sectionController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    label: 'Section',
                                    icon: Icons.meeting_room_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: _buildInputDecoration(
                                    label: 'Capacity (Seats)',
                                    icon: Icons.group_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(value);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Must be > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : _submitForm,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Save Subject',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.tealAccent,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
      ),
    );
  }
}
