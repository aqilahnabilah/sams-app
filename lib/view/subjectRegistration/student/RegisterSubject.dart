import 'package:flutter/material.dart';
import '../../../provider/subjectregistration/SubjectRegistrationController.dart';

class RegisterSubjectPage extends StatefulWidget {
  final String studentEmail;
  final String studentName;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final int creditHour;
  final String examDate;
  final String examTime;
  final List<dynamic> lectures;
  final List<dynamic> labs;

  const RegisterSubjectPage({
    super.key,
    required this.studentEmail,
    required this.studentName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.creditHour,
    required this.examDate,
    required this.examTime,
    required this.lectures,
    required this.labs,
  });

  @override
  State<RegisterSubjectPage> createState() => _RegisterSubjectPageState();
}

class _RegisterSubjectPageState extends State<RegisterSubjectPage> {
  final SubjectRegistrationController _registrationController = SubjectRegistrationController();
  String? _selectedSection;
  String? _selectedLab;
  bool _isRegistering = false;

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime24hTo12h(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _handleRegister() async {
    if (_selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class section.')),
      );
      return;
    }

    final matchingLabs = widget.labs.where(
      (lab) => lab['parentLecture'] == _selectedSection,
    ).toList();

    if (matchingLabs.isNotEmpty && _selectedLab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lab section.')),
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Check if student has already registered for this subject (either approved or pending)
      final hasAlreadyRegistered = await _registrationController.checkAlreadyRegistered(
        studentEmail: widget.studentEmail,
        subjectId: widget.subjectId,
      );
      if (hasAlreadyRegistered) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1F1C2C),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text('Duplicate Registration', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: const Text(
                'You have already submitted a registration request or are already registered for this subject.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      // Find selected lecture and matching labs
      final selectedLec = widget.lectures.firstWhere(
        (lec) => lec['name'] == _selectedSection,
        orElse: () => null,
      );

      if (selectedLec == null) {
        throw Exception('Selected lecture section not found.');
      }

      final List<dynamic> chosenLabs = [];
      if (_selectedLab != null) {
        final selectedLab = widget.labs.firstWhere(
          (lab) => lab['name'] == _selectedLab && lab['parentLecture'] == _selectedSection,
          orElse: () => null,
        );
        if (selectedLab != null) {
          chosenLabs.add(selectedLab);
        }
      }

      // Check clash
      final hasClash = await _registrationController.checkScheduleClash(
        studentEmail: widget.studentEmail,
        selectedLecture: selectedLec,
        selectedLabs: chosenLabs,
      );
      if (hasClash) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1F1C2C),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Schedule Clash', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: const Text(
                'The subject is clashing with other subject.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.tealAccent)),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      // Submit registration
      await _registrationController.submitRegistration(
        studentEmail: widget.studentEmail,
        studentName: widget.studentName,
        subjectId: widget.subjectId,
        subjectCode: widget.subjectCode,
        subjectName: widget.subjectName,
        sectionName: _selectedSection!,
        labSectionName: _selectedLab,
        examDate: widget.examDate,
        examTime: widget.examTime,
        creditHour: widget.creditHour,
        lectures: [
          {
            'name': selectedLec['name'],
            'day': selectedLec['day'],
            'startTime': selectedLec['startTime'],
            'endTime': selectedLec['endTime'],
          }
        ],
        labs: chosenLabs.map((lab) => {
          'name': lab['name'],
          'day': lab['day'],
          'startTime': lab['startTime'],
          'endTime': lab['endTime'],
        }).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration submitted. Pending advisor approval.')),
        );
        Navigator.of(context).pop(); // Go back to subject list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button & Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Register Subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subject details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade500.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.teal.shade400.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.subjectCode,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subjectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.examDate.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 8),
                            Text(
                              'Exam: ${_formatDateString(widget.examDate)}' + (widget.examTime.isNotEmpty ? ' @ ${_formatTime24hTo12h(widget.examTime)}' : ''),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Select Class Section',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Class sections radio list
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.lectures.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final lec = widget.lectures[index];
                      final String sectionName = lec['name'] ?? '';
                      final int capacity = (lec['capacity'] as num?)?.toInt() ?? 0;
                      final int registered = (lec['registeredCount'] as num?)?.toInt() ?? 0;
                      final int available = capacity - registered;
                      final bool isSectionFull = available <= 0;

                      final matchingLabs = widget.labs.where(
                        (lab) => lab['parentLecture'] == sectionName,
                      ).toList();

                      final isSelected = _selectedSection == sectionName;

                      return GestureDetector(
                        onTap: isSectionFull
                            ? null
                            : () {
                                setState(() {
                                  _selectedSection = sectionName;
                                  _selectedLab = null; // Clear lab when changing section
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.tealAccent.withOpacity(0.08)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.tealAccent.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Opacity(
                            opacity: isSectionFull ? 0.5 : 1.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Radio<String>(
                                  value: sectionName,
                                  groupValue: _selectedSection,
                                  activeColor: Colors.tealAccent,
                                  onChanged: isSectionFull
                                      ? null
                                      : (val) {
                                          setState(() {
                                            _selectedSection = val;
                                            _selectedLab = null; // Clear lab when changing section
                                          });
                                        },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Section $sectionName',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            isSectionFull ? 'FULL' : '$available Left',
                                            style: TextStyle(
                                              color: isSectionFull ? Colors.redAccent : Colors.tealAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.5)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${lec['day']} • ${lec['startTime']}-${lec['endTime']}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (matchingLabs.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.06),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Select Lab Section:',
                                          style: TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...matchingLabs.map((lab) {
                                          final String labName = lab['name'] ?? '';
                                          final int labCapacity = (lab['capacity'] as num?)?.toInt() ?? 0;
                                          final int labRegistered = (lab['registeredCount'] as num?)?.toInt() ?? 0;
                                          final int labAvailable = labCapacity - labRegistered;
                                          final bool isLabFull = labAvailable <= 0;

                                          final isLabSelected = _selectedLab == labName;

                                          return GestureDetector(
                                            onTap: isLabFull || !isSelected
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _selectedLab = labName;
                                                    });
                                                  },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isLabSelected
                                                    ? Colors.tealAccent.withOpacity(0.06)
                                                    : Colors.white.withOpacity(0.03),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isLabSelected
                                                      ? Colors.tealAccent.withOpacity(0.4)
                                                      : Colors.white.withOpacity(0.05),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (isSelected) ...[
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: Radio<String>(
                                                        value: labName,
                                                        groupValue: _selectedLab,
                                                        activeColor: Colors.tealAccent,
                                                        onChanged: isLabFull
                                                            ? null
                                                            : (val) {
                                                                setState(() {
                                                                  _selectedLab = val;
                                                                });
                                                              },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              labName,
                                                              style: TextStyle(
                                                                color: isLabSelected ? Colors.tealAccent : Colors.white70,
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            Text(
                                                              isLabFull ? 'FULL' : '$labAvailable Left',
                                                              style: TextStyle(
                                                                color: isLabFull ? Colors.redAccent : Colors.tealAccent,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.science_outlined, size: 13, color: Colors.white.withOpacity(0.5)),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              '${lab['day']} • ${lab['startTime']}-${lab['endTime']}',
                                                              style: TextStyle(
                                                                color: Colors.white.withOpacity(0.6),
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade400,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.tealAccent.shade400.withOpacity(0.3),
                    ),
                    onPressed: _isRegistering ? null : _handleRegister,
                    child: _isRegistering
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Register Subject',
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
        ),
      ),
    );
  }
}
