import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'ClaimConfirmationPage.dart';
import 'ClaimStatusPage.dart';

class CoCurriculumPage extends StatefulWidget {
  final String student_id;
  final String full_name;

  const CoCurriculumPage({
    super.key,
    required this.student_id,
    required this.full_name,
  });

  @override
  State<CoCurriculumPage> createState() => _CoCurriculumPageState();
}

class _CoCurriculumPageState extends State<CoCurriculumPage> {
  @override
  void initState() {
    super.initState();

    // Fetch co-curriculum records when the page is opened.
    fetchCoCurriculumRecords();
  }

  // This method retrieves student co-curriculum records from Firestore.
  // It follows the Boundary/View responsibility in the SDD.
  void fetchCoCurriculumRecords() {
    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getStudentRecords(widget.student_id);
    });
  }

  // This method maps the student to the claim confirmation page.
  void mapsToClaimConfirmation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimConfirmationPage(
          student_id: widget.student_id,
          full_name: widget.full_name,
        ),
      ),
    );
  }

  // This method maps the student to the claim status page.
  void mapsToClaimStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimStatusPage(
          student_id: widget.student_id,
        ),
      ),
    );
  }

  // This method displays current logged-in student information.
  void displayProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: Color(0xFF1F7A5C),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Role',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              const Text(
                'Student',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Name',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              Text(
                widget.full_name,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Email / Student ID',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              Text(
                widget.student_id,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F7A5C),
            elevation: 0,
            title: const Text(
              'Manage Co-curriculum',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    displayProfileDialog(context);
                  },
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Text(
                      'S',
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
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.getStudentRecords(widget.student_id);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        displayCompletedModuleCount(controller),
                        const SizedBox(height: 16),
                        displayCoCurriculumRecords(controller),
                        const SizedBox(height: 22),
                        displayClaimButtons(context),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // This method displays the completed module count.
  // Student must complete at least 4 modules before submitting a claim.
  Widget displayCompletedModuleCount(CoCurriculumController controller) {
    final completedCount = controller.getCompletedModuleCount();
    final isEligible = completedCount >= 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isEligible
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEligible
              ? const Color(0xFF81C784)
              : const Color(0xFFFFB74D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.info,
            color: isEligible
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedCount / 4 Modules Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEligible
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEligible
                      ? 'You are eligible to claim co-curriculum credit.'
                      : 'You must complete 4 modules before submitting a claim.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isEligible
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This method displays the list of co-curriculum records retrieved from Firestore.
  Widget displayCoCurriculumRecords(CoCurriculumController controller) {
    if (controller.records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.folder_open,
              color: Color(0xFF9CA3AF),
              size: 46,
            ),
            SizedBox(height: 10),
            Text(
              'No co-curriculum record found.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Co-curriculum Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: controller.records.map((record) {
              final module = controller.modules[record.module_id];

              final moduleName = module?.module_name ?? record.module_id;
              final moduleCategory =
                  module?.module_category ?? 'Co-curriculum Module';

              final isCompleted = record.isCompleted();

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isCompleted
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.hourglass_empty,
                        color: isCompleted
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moduleName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: $moduleCategory',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${record.completion_status}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // This method displays navigation buttons for claim confirmation and claim status.
  Widget displayClaimButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(
              Icons.upload_file,
              color: Colors.white,
            ),
            label: const Text(
              'Submit Co-curriculum Claim',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              mapsToClaimConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F7A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.fact_check,
              color: Color(0xFF1F7A5C),
            ),
            label: const Text(
              'View Claim Status',
              style: TextStyle(
                color: Color(0xFF1F7A5C),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              mapsToClaimStatus(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1F7A5C),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}