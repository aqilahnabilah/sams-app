import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumModuleModel.dart';
import '../../domain/co_curriculum/StudentCoCurriculumRecordModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'ClaimConfirmationPage.dart';
import 'ClaimStatusPage.dart';
import 'CoCurriculumPage.dart';

class RegisterModulePage extends StatefulWidget {
  final String student_id;
  final String full_name;

  const RegisterModulePage({
    super.key,
    required this.student_id,
    required this.full_name,
  });

  @override
  State<RegisterModulePage> createState() => _RegisterModulePageState();
}

class _RegisterModulePageState extends State<RegisterModulePage> {
  @override
  void initState() {
    super.initState();
    fetchModuleData();
  }

  void fetchModuleData() {
    Future.microtask(() async {
      final controller = Provider.of<CoCurriculumController>(
        context,
        listen: false,
      );

      await controller.getAvailableModules();
      await controller.getStudentRecords(widget.student_id);
    });
  }

  Future<void> registerSelectedModule(String module_id) async {
    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    final message = await controller.registerModule(
      student_id: widget.student_id,
      module_id: module_id,
    );

    if (!mounted) {
      return;
    }

    showMessage(message);
  }

  Future<void> markSelectedModuleAsCompleted(
    StudentCoCurriculumRecordModel record,
  ) async {
    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    final message = await controller.markModuleAsCompleted(
      student_id: widget.student_id,
      record: record,
    );

    if (!mounted) {
      return;
    }

    showMessage(message);
  }

  Future<void> logoutUser() async {
    final authService = AuthService();
    await authService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(),
      ),
      (route) => false,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1F7A5C),
      ),
    );
  }

  String readValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    if (value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  void displayProfileDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Student Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('Student')
                .doc(widget.student_id)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final data = snapshot.data?.data() ?? {};

              final fullName = readValue(
                data,
                'full_name',
                widget.full_name,
              );

              final studentEmail = readValue(
                data,
                'student_email',
                widget.student_id,
              );

              final programCode = readValue(
                data,
                'program_code',
                '-',
              );

              final programName = readValue(
                data,
                'program_name',
                '-',
              );

              final faculty = readValue(
                data,
                'faculty',
                readValue(data, 'Faculty', '-'),
              );

              final currentSem = readValue(
                data,
                'current_sem',
                '-',
              );

              final coCurriculumCredit = readValue(
                data,
                'co_curriculum_credit',
                '0',
              );

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Color(0xFF1F7A5C),
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    displayProfileItem(
                      label: 'Role',
                      value: 'Student',
                    ),
                    displayProfileItem(
                      label: 'full_name',
                      value: fullName,
                    ),
                    displayProfileItem(
                      label: 'student_email',
                      value: studentEmail,
                    ),
                    displayProfileItem(
                      label: 'program_code',
                      value: programCode,
                    ),
                    displayProfileItem(
                      label: 'program_name',
                      value: programName,
                    ),
                    displayProfileItem(
                      label: 'faculty',
                      value: faculty,
                    ),
                    displayProfileItem(
                      label: 'current_sem',
                      value: currentSem,
                    ),
                    displayProfileItem(
                      label: 'co_curriculum_credit',
                      value: coCurriculumCredit,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF1F7A5C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget displayProfileItem({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            backgroundColor: const Color(0xFF1F7A5C),
            elevation: 0,
            title: const Text(
              'Register Module',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PopupMenuButton<String>(
                  tooltip: 'User Menu',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      displayProfileDialog();
                    }

                    if (value == 'logout') {
                      await logoutUser();
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Color(0xFF1F7A5C),
                            ),
                            SizedBox(width: 10),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Color(0xFF1F7A5C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.getAvailableModules();
                    await controller.getStudentRecords(widget.student_id);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        displayHeaderCard(controller),
                        const SizedBox(height: 18),
                        displayAvailableModules(controller),
                        const SizedBox(height: 18),
                        displayRegisteredModules(controller),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget displayHeaderCard(CoCurriculumController controller) {
    final registeredCount = controller.getRegisteredModuleCount();
    final completedCount = controller.getCompletedModuleCount();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A5C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              'U',
              style: TextStyle(
                color: Color(0xFF1F7A5C),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Module Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$registeredCount registered module(s), $completedCount completed module(s).',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget displayAvailableModules(CoCurriculumController controller) {
    final registeredModuleIds = controller.records
        .map((record) => record.module_id)
        .toList();

    if (controller.availableModules.isEmpty) {
      return displayEmptyCard(
        icon: Icons.event_busy,
        title: 'No Available Module',
        description:
            'There is no active co-curriculum module for registration.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: displayCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Available Modules',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.availableModules.length} Active',
                  style: const TextStyle(
                    color: Color(0xFF1F7A5C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: controller.availableModules.map((module) {
              final isRegistered = registeredModuleIds.contains(
                module.module_id,
              );

              return displayAvailableModuleCard(
                module: module,
                isRegistered: isRegistered,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget displayAvailableModuleCard({
    required CoCurriculumModuleModel module,
    required bool isRegistered,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.module_name,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Category: ${module.module_category}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${formatNullableDate(module.module_date)}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Credit Value: ${module.credit_value}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: isRegistered
                  ? null
                  : () {
                      registerSelectedModule(module.module_id);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF1F7A5C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isRegistered ? 'Already Registered' : 'Register Module',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget displayRegisteredModules(CoCurriculumController controller) {
    if (controller.records.isEmpty) {
      return displayEmptyCard(
        icon: Icons.assignment_outlined,
        title: 'No Registered Module',
        description: 'Registered modules appear here after you register.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: displayCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Registered Modules',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: controller.records.map((record) {
              final module = controller.modules[record.module_id];

              return displayRegisteredModuleCard(
                record: record,
                module: module,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget displayRegisteredModuleCard({
    required StudentCoCurriculumRecordModel record,
    required CoCurriculumModuleModel? module,
  }) {
    final isCompleted = record.isCompleted();
    final canMarkCompleted = module?.isModuleDateReached() ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module?.module_name ?? record.module_id,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Date: ${formatNullableDate(module?.module_date)}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${record.completion_status}',
            style: TextStyle(
              color: isCompleted
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (isCompleted)
            displayStatusBadge(
              text: 'Completed',
              backgroundColor: const Color(0xFFE8F5E9),
              textColor: const Color(0xFF2E7D32),
              icon: Icons.check_circle,
            )
          else if (canMarkCompleted)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  markSelectedModuleAsCompleted(record);
                },
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                label: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F7A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            displayStatusBadge(
              text:
                  'You can mark this module as completed after the module date.',
              backgroundColor: const Color(0xFFFFF3E0),
              textColor: const Color(0xFFE65100),
              icon: Icons.schedule,
            ),
        ],
      ),
    );
  }

  Widget displayEmptyCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: displayCardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9CA3AF),
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget displayStatusBadge({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration displayCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  String formatNullableDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
