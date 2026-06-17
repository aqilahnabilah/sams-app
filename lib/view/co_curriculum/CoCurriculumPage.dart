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

    Future.microtask(() {
      Provider.of<CoCurriculumController>(
        context,
        listen: false,
      ).getStudentRecords(widget.student_id);
    });
  }

  void mapsToClaimConfirmation(int completed_module_count) {
    if (completed_module_count >= 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClaimConfirmationPage(
            student_id: widget.student_id,
            completed_module_count: completed_module_count,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must complete 4 co-curriculum modules before claiming credit.',
          ),
        ),
      );
    }
  }

  void mapsToClaimStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimStatusPage(
          student_id: widget.student_id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        final completed_module_count = controller.getCompletedModuleCount();

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(completed_module_count),
                        const SizedBox(height: 16),
                        _buildEligibilityCard(completed_module_count),
                        const SizedBox(height: 16),
                        _buildActionButtons(completed_module_count),
                        const SizedBox(height: 24),
                        const Text(
                          'Co-curriculum Record',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecordList(controller),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderCard(int completed_module_count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Co-curriculum Summary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.full_name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student ID: ${widget.student_id}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'Completed Modules',
                  value: '$completed_module_count / 4',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryBox(
                  title: 'Claim Credit',
                  value: '2 Credits',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityCard(int completed_module_count) {
    final isEligible = completed_module_count >= 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEligible
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
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
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEligible
                  ? 'You are eligible to submit co-curriculum credit claim.'
                  : 'You need to complete at least 4 co-curriculum modules before claiming credit.',
              style: TextStyle(
                color: isEligible
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int completed_module_count) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              mapsToClaimConfirmation(completed_module_count);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F7A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Submit Claim',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: mapsToClaimStatus,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1F7A5C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'View Claim Status',
              style: TextStyle(
                color: Color(0xFF1F7A5C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordList(CoCurriculumController controller) {
    if (controller.error_message.isNotEmpty) {
      return Center(
        child: Text(
          controller.error_message,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (controller.records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'No co-curriculum record found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Column(
      children: controller.records.map((record) {
        final isCompleted = record.isCompleted();

        final module = controller.modules[record.module_id];
        final moduleName = module?.module_name ?? record.module_id;
        final moduleCategory =
            module?.module_category ?? 'Co-curriculum Module';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isCompleted
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                child: Icon(
                  isCompleted ? Icons.check : Icons.hourglass_bottom,
                  color: isCompleted
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moduleName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: $moduleCategory\nStatus: ${record.completion_status}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isCompleted ? 'Completed' : 'Incomplete',
                style: TextStyle(
                  color: isCompleted
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}