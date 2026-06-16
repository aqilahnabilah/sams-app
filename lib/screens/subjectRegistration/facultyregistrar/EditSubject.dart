// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/course_service.dart';

// Model to hold the state of a single lab session input
class LabInput {
  final TextEditingController nameController;
  final TextEditingController capacityController;
  String day;
  TimeOfDay startTime;
  TimeOfDay endTime;

  LabInput({
    required String name,
    required String capacity,
    required this.day,
    required this.startTime,
    required this.endTime,
  }) : nameController = TextEditingController(text: name),
       capacityController = TextEditingController(text: capacity);

  void dispose() {
    nameController.dispose();
    capacityController.dispose();
  }
}

// Model to hold the state of a single lecture session input, containing its nested labs
class LectureInput {
  final TextEditingController nameController;
  final TextEditingController capacityController;
  String day;
  TimeOfDay startTime;
  TimeOfDay endTime;
  final List<LabInput> labs;

  LectureInput({
    required String name,
    required String capacity,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.labs,
  }) : nameController = TextEditingController(text: name),
       capacityController = TextEditingController(text: capacity);

  void dispose() {
    nameController.dispose();
    capacityController.dispose();
    for (var lab in labs) {
      lab.dispose();
    }
  }
}

// SAMS-REQ-103: Display the edit subject info form
class EditSubjectPage extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;

  const EditSubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectData,
  });

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _creditController = TextEditingController();
  final _examDateController = TextEditingController();
  final _examTimeController = TextEditingController();
  DateTime? _selectedExamDate;
  TimeOfDay? _selectedExamTime;
  
  // List of days of the week for scheduling
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // List of dynamic lecture session inputs (each containing its nested labs)
  final List<LectureInput> _lectures = [];

  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  String? _errorMessage;

  // Converts a DateTime object to an ISO-8601 date string format (YYYY-MM-DD)
  String _toIsoDateString(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Parses an ISO-8601 date string (YYYY-MM-DD) back into a DateTime object
  DateTime? _parseIsoDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  //Formats an ISO-8601 date string (YYYY-MM-DD) to a user-friendly readable format, e.g. "16 Jun 2026"
  String _formatDateString(String dateStr) {
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

  // Converts a 24-hour time string (HH:mm) to a 12-hour format with AM/PM (e.g. "14:00" -> "2:00 PM")
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

  //  Parses a 24-hour time string (HH:mm) into a TimeOfDay object
  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  //  Flutter lifecycle method called when the state object is created; initializes form values from existing subject data
  @override
  void initState() {
    super.initState();
    
    // Populate form fields from Firestore document data
    final data = widget.subjectData;
    _codeController.text = data['code'] ?? '';
    _nameController.text = data['name'] ?? '';
    _lecturerController.text = data['lecturer'] ?? '';
    _creditController.text = (data['creditHour'] ?? '').toString();
    _examDateController.text = data['examDate'] != null ? _formatDateString(data['examDate']) : '';
    _selectedExamDate = _parseIsoDateString(data['examDate']);
    final String rawExamTime = data['examTime'] ?? '';
    if (rawExamTime.isNotEmpty) {
      _selectedExamTime = _parseTimeString(rawExamTime);
      _examTimeController.text = _formatTime24hTo12h(rawExamTime);
    }

    final List<dynamic> lecturesData = data['lectures'] ?? [];
    final List<dynamic> labsData = data['labs'] ?? [];

    for (var lecMap in lecturesData) {
      final String lecName = lecMap['name'] ?? '';
      final int lecCap = (lecMap['capacity'] as num?)?.toInt() ?? 0;
      final String lecDay = lecMap['day'] ?? 'Monday';
      final String lecStartStr = lecMap['startTime'] ?? '08:00';
      final String lecEndStr = lecMap['endTime'] ?? '10:00';

      final lecStart = _parseTimeString(lecStartStr);
      final lecEnd = _parseTimeString(lecEndStr);

      final List<LabInput> associatedLabs = [];
      final lecture = LectureInput(
        name: lecName,
        capacity: lecCap.toString(),
        day: lecDay,
        startTime: lecStart,
        endTime: lecEnd,
        labs: associatedLabs,
      );

      for (var labMap in labsData) {
        if (labMap['parentLecture'] == lecName) {
          final String labName = labMap['name'] ?? '';
          final int labCap = (labMap['capacity'] as num?)?.toInt() ?? 0;
          final String labDay = labMap['day'] ?? 'Tuesday';
          final String labStartStr = labMap['startTime'] ?? '10:00';
          final String labEndStr = labMap['endTime'] ?? '12:00';

          final labStart = _parseTimeString(labStartStr);
          final labEnd = _parseTimeString(labEndStr);

          final lab = LabInput(
            name: labName,
            capacity: labCap.toString(),
            day: labDay,
            startTime: labStart,
            endTime: labEnd,
          );
          lab.capacityController.addListener(() => _updateLectureCapacity(lecture));
          associatedLabs.add(lab);
        }
      }

      _lectures.add(lecture);
      _updateLectureCapacity(lecture);
    }
  }

  //  Adds a nested Lab session input under the specified Lecture session
  void _addLabToLecture(LectureInput lecture) {
    final lecName = lecture.nameController.text.trim();
    
    // Auto-generate next suffix lab section name, e.g. "01" -> "01A", "01B" etc.
    String suffix = 'A';
    if (lecture.labs.isNotEmpty) {
      final lastLabName = lecture.labs.last.nameController.text.trim();
      if (lastLabName.length > lecName.length) {
        final lastChar = lastLabName.substring(lecName.length);
        if (lastChar.isNotEmpty) {
          final code = lastChar.codeUnitAt(0);
          suffix = String.fromCharCode(code + 1);
        }
      }
    }
    final labName = '$lecName$suffix';

    final newLab = LabInput(
      name: labName,
      capacity: '30',
      day: 'Tuesday',
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
    );
    newLab.capacityController.addListener(() => _updateLectureCapacity(lecture));

    setState(() {
      lecture.labs.add(newLab);
    });

    _updateLectureCapacity(lecture);
  }

  // : Automatically updates the read-only Lecture capacity input by summing the capacities of all its nested Labs
  void _updateLectureCapacity(LectureInput lecture) {
    int totalCap = 0;
    for (var lab in lecture.labs) {
      totalCap += int.tryParse(lab.capacityController.text.trim()) ?? 0;
    }
    final newCapStr = totalCap.toString();
    if (lecture.capacityController.text != newCapStr) {
      lecture.capacityController.text = newCapStr;
    }
  }

  // Removes a Lecture session input from the form, along with its nested Labs
  void _removeLecture(int index) {
    if (_lectures.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one Lecture session is required.')),
      );
      return;
    }
    setState(() {
      _lectures[index].dispose();
      _lectures.removeAt(index);
    });
  }

  //  Removes a nested Lab session input from under the specified Lecture session
  void _removeLab(LectureInput lecture, int labIndex) {
    if (lecture.labs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one Lab session is required.')),
      );
      return;
    }
    setState(() {
      lecture.labs[labIndex].dispose();
      lecture.labs.removeAt(labIndex);
    });
    _updateLectureCapacity(lecture);
  }

  //  Flutter lifecycle method called when the state object is destroyed; disposes of all controllers to release memory
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _lecturerController.dispose();
    _creditController.dispose();
    _examDateController.dispose();
    _examTimeController.dispose();
    for (var section in _lectures) {
      section.dispose();
    }
    super.dispose();
  }

  //  Formats a TimeOfDay object to a user-friendly local time string, e.g. "9:00 AM" or "2:30 PM"
  String _formatTimeOfDay(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  //  Converts a TimeOfDay object to a standard 24-hour time string (HH:mm) for database persistence
  String _to24hString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  //  Validates class session times, ensuring the End Time is after the Start Time and duration is at least 2 hours
  bool _validateClassTimes(String name, String type, TimeOfDay start, TimeOfDay end) {
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    final durationMins = endMins - startMins;

    if (durationMins <= 0) {
      setState(() {
        _errorMessage = '$type $name: End Time must be after Start Time.';
      });
      return false;
    }

    if (durationMins < 120) { // 120 minutes = 2 hours
      setState(() {
        _errorMessage = '$type $name: Class duration must be at least 2 hours.';
      });
      return false;
    }

    return true;
  }

  //  Validates the entire form, builds the lecture and lab data payloads, and updates the existing subject in Firestore
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate times for both lectures and nested labs
    for (var lec in _lectures) {
      final lecName = lec.nameController.text.trim();
      if (!_validateClassTimes(lecName, 'Lecture', lec.startTime, lec.endTime)) return;
      for (var lab in lec.labs) {
        final labName = lab.nameController.text.trim();
        if (!_validateClassTimes(labName, 'Lab', lab.startTime, lab.endTime)) return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim();
      final name = _nameController.text.trim();
      final lecturer = _lecturerController.text.trim();
      final creditHour = int.parse(_creditController.text.trim());
      final examDate = _selectedExamDate != null ? _toIsoDateString(_selectedExamDate!) : '';
      final examTime = _selectedExamTime != null ? _to24hString(_selectedExamTime!) : '';

      // Build flatten payloads
      List<Map<String, dynamic>> lecturesPayload = [];
      List<Map<String, dynamic>> labsPayload = [];

      for (var lec in _lectures) {
        final lecName = lec.nameController.text.trim().toUpperCase();
        lecturesPayload.add({
          'name': lecName,
          'capacity': int.parse(lec.capacityController.text.trim()),
          'registeredCount': 0,
          'day': lec.day,
          'startTime': _to24hString(lec.startTime),
          'endTime': _to24hString(lec.endTime),
        });

        for (var lab in lec.labs) {
          labsPayload.add({
            'name': lab.nameController.text.trim().toUpperCase(),
            'parentLecture': lecName,
            'capacity': int.parse(lab.capacityController.text.trim()),
            'registeredCount': 0,
            'day': lab.day,
            'startTime': _to24hString(lab.startTime),
            'endTime': _to24hString(lab.endTime),
          });
        }
      }

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Edit Mode: Update existing subject document
      await _courseService.updateSubject(
        documentId: widget.subjectId,
        code: code,
        name: name,
        lecturer: lecturer,
        creditHour: creditHour,
        examDate: examDate,
        examTime: examTime,
        lectures: lecturesPayload,
        labs: labsPayload,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('Subject $code updated successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
      navigator.pop(); // Go back to course main page
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

  //  Flutter build method that describes the UI hierarchy of the Edit Subject screen
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
                    // Header Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Subject',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SAMS-REQ-103: Display the edit subject info form
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
                            'Course Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

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

                          // Credit Hour
                          TextFormField(
                            controller: _creditController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              label: 'Credit Hour',
                              icon: Icons.hourglass_empty,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter credit hour';
                              }
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Must be a positive number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              // Exam Date Picker
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedExamDate ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: Colors.tealAccent,
                                              onPrimary: Colors.black,
                                              surface: Color(0xFF1F1C2C),
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedExamDate = picked;
                                        _examDateController.text = _formatDateString(_toIsoDateString(picked));
                                      });
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: TextFormField(
                                      controller: _examDateController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration(
                                        label: 'Exam Date',
                                        icon: Icons.calendar_today,
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Exam Time Picker
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedExamTime ?? const TimeOfDay(hour: 9, minute: 0),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: Colors.tealAccent,
                                              onPrimary: Colors.black,
                                              surface: Color(0xFF1F1C2C),
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedExamTime = picked;
                                        _examTimeController.text = _formatTime24hTo12h(_to24hString(picked));
                                      });
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: TextFormField(
                                      controller: _examTimeController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration(
                                        label: 'Exam Time',
                                        icon: Icons.access_time,
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // LECTURE & LAB GROUPS SECTION
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lecture & Lab Groups',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // No adding sections in Edit Mode for simplicity or keep it same as add
                            ],
                          ),
                          const SizedBox(height: 12),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lectures.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final lec = _lectures[index];
                              return _buildLectureCard(lec, index);
                            },
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
                                      'Update Subject',
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

  //  Widget builder that builds the card UI for a Lecture section, including its fields and nested Labs list
  Widget _buildLectureCard(LectureInput lec, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: lec.nameController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    label: 'Section',
                    hintText: 'e.g. 01',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: lec.capacityController,
                  readOnly: true,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  decoration: _buildInputDecoration(
                    label: 'Capacity',
                    hintText: 'Auto',
                    isDense: true,
                  ),
                  validator: (value) {
                    final p = int.tryParse(value ?? '0');
                    if (p == null || p <= 0) return 'Must be > 0 (Add Labs)';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 22),
                onPressed: () => _removeLecture(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: lec.day,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF1E1E2E),
            decoration: _buildInputDecoration(
              label: 'Day',
              isDense: true,
            ),
            items: _daysOfWeek.map((day) {
              return DropdownMenuItem<String>(
                value: day,
                child: Text(day),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  lec.day = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  context: context,
                  label: 'Start Time',
                  time: lec.startTime,
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: lec.startTime,
                    );
                    if (selected != null) {
                      setState(() {
                        lec.startTime = selected;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeButton(
                  context: context,
                  label: 'End Time',
                  time: lec.endTime,
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: lec.endTime,
                    );
                    if (selected != null) {
                      setState(() {
                        lec.endTime = selected;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Labs under Lecture ${lec.nameController.text.trim()}',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addLabToLecture(lec),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.tealAccent),
                label: const Text(
                  'Add Lab',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (lec.labs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No lab sessions added yet.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: lec.labs.asMap().entries.map((entry) {
                final labIndex = entry.key;
                final lab = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildNestedLabCard(lec, lab, labIndex),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  //  Widget builder that builds the card UI for a nested Lab section under a Lecture
  Widget _buildNestedLabCard(LectureInput lec, LabInput lab, int labIndex) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: lab.nameController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _buildInputDecoration(
                    label: 'Section',
                    hintText: 'e.g. 01A',
                    isDense: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: lab.capacityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _buildInputDecoration(
                    label: 'Capacity',
                    hintText: '30',
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                onPressed: () => _removeLab(lec, labIndex),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: lab.day,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            dropdownColor: const Color(0xFF1E1E2E),
            decoration: _buildInputDecoration(
              label: 'Day',
              isDense: true,
            ),
            items: _daysOfWeek.map((day) {
              return DropdownMenuItem<String>(
                value: day,
                child: Text(day.substring(0, 3)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  lab.day = val;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  context: context,
                  label: 'Start Time',
                  time: lab.startTime,
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: lab.startTime,
                    );
                    if (selected != null) {
                      setState(() {
                        lab.startTime = selected;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeButton(
                  context: context,
                  label: 'End Time',
                  time: lab.endTime,
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: lab.endTime,
                    );
                    if (selected != null) {
                      setState(() {
                        lab.endTime = selected;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget builder that builds a custom button field for picking Start and End times
  Widget _buildTimeButton({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeOfDay(context, time),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time_outlined,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  //  Helper that creates a uniform glassmorphic InputDecoration for text form fields and dropdowns
  InputDecoration _buildInputDecoration({
    required String label,
    IconData? icon,
    bool isDense = false,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: isDense ? 12 : 14,
      ),
      isDense: isDense,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: isDense ? 11 : 14,
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: Colors.white.withOpacity(0.6),
              size: isDense ? 16 : 24,
            )
          : null,
      contentPadding: isDense ? const EdgeInsets.symmetric(vertical: 10, horizontal: 10) : null,
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
