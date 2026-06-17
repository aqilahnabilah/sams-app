// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dashboards.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Student ERD fields.
  final _programCodeController = TextEditingController();
  final _programNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _currentSemController = TextEditingController();

  // Pusat ADAB ERD fields.
  final _departmentController = TextEditingController(text: 'Pusat ADAB');
  final _statusController = TextEditingController(text: 'Active');

  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Selected role: 'student', 'lecturer', 'faculty_registrar', 'pusat_adab'
  String _selectedRole = 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _programCodeController.dispose();
    _programNameController.dispose();
    _facultyController.dispose();
    _currentSemController.dispose();
    _departmentController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // OOP METHOD: This method registers the user and sends ERD fields to Firebase.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        programCode: _programCodeController.text.trim(),
        programName: _programNameController.text.trim(),
        faculty: _facultyController.text.trim(),
        currentSem: int.tryParse(_currentSemController.text.trim()) ?? 0,
        department: _departmentController.text.trim(),
        status: _statusController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        if (mounted) {
          _routeToDashboard(
            _selectedRole,
            user.email ?? '',
            _nameController.text.trim(),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _routeToDashboard(String role, String email, String name) {
    Widget nextScreen;

    switch (role) {
      case 'student':
        nextScreen = StudentDashboard(
          email: email,
          name: name,
        );
        break;

      case 'lecturer':
        nextScreen = LecturerDashboard(
          email: email,
          name: name,
        );
        break;

      case 'faculty_registrar':
        nextScreen = RegistrarDashboard(
          email: email,
          name: name,
        );
        break;

      case 'pusat_adab':
        nextScreen = PusatAdabDashboard(
          email: email,
          name: name,
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid role: $role'),
          ),
        );
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => nextScreen,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }

                              final emailRegex = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#\$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                              );

                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.teal,
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
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }

                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _buildRoleCard(
                            roleValue: 'student',
                            title: 'Student',
                            description: 'Register and view subjects',
                            icon: Icons.school,
                          ),

                          const SizedBox(height: 8),

                          _buildRoleCard(
                            roleValue: 'lecturer',
                            title: 'Lecturer',
                            description: 'Manage class rosters and grading',
                            icon: Icons.menu_book,
                          ),

                          const SizedBox(height: 8),

                          _buildRoleCard(
                            roleValue: 'faculty_registrar',
                            title: 'Faculty Registrar',
                            description: 'Administer system registration parameters',
                            icon: Icons.admin_panel_settings,
                          ),

                          const SizedBox(height: 8),

                          _buildRoleCard(
                            roleValue: 'pusat_adab',
                            title: 'Pusat ADAB',
                            description: 'Manage co-curriculum modules and verify claims',
                            icon: Icons.verified_user,
                          ),

                          _buildRoleExtraFields(),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
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
                                      'Register',
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

  // OOP METHOD: This method displays extra register fields based on selected role.
  Widget _buildRoleExtraFields() {
    if (_selectedRole == 'student') {
      return _buildStudentExtraFields();
    }

    if (_selectedRole == 'pusat_adab') {
      return _buildPusatAdabExtraFields();
    }

    return const SizedBox.shrink();
  }

  // OOP METHOD: This method builds Student ERD attribute inputs.
  Widget _buildStudentExtraFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Text(
          'Student Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _programCodeController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Program Code',
            icon: Icons.badge_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter program code';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _programNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Program Name',
            icon: Icons.school_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter program name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _facultyController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Faculty',
            icon: Icons.account_balance_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter faculty';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _currentSemController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Current Semester',
            icon: Icons.calendar_month_outlined,
          ),
          validator: (value) {
            final sem = int.tryParse((value ?? '').trim());
            if (sem == null) {
              return 'Please enter current semester';
            }
            if (sem < 1 || sem > 8) {
              return 'Semester must be between 1 and 8';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Co-curriculum credit will be saved as 0 automatically.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // OOP METHOD: This method builds Pusat ADAB ERD attribute inputs.
  Widget _buildPusatAdabExtraFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Text(
          'Pusat ADAB Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _departmentController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Department',
            icon: Icons.business_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter department';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _statusController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            label: 'Status',
            icon: Icons.verified_outlined,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter status';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Role will be saved as Pusat ADAB automatically.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 12,
          ),
        ),
      ],
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
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.teal,
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

  Widget _buildRoleCard({
    required String roleValue,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == roleValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.teal.withOpacity(0.25)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.tealAccent : Colors.white70,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.tealAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
