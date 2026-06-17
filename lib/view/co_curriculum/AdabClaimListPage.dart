import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/co_curriculum/CoCurriculumClaimModel.dart';
import '../../provider/co_curriculum/CoCurriculumController.dart';
import 'AdabClaimDetailPage.dart';

class AdabClaimListPage extends StatefulWidget {
  final String staff_id;

  const AdabClaimListPage({
    super.key,
    required this.staff_id,
  });

  @override
  State<AdabClaimListPage> createState() => _AdabClaimListPageState();
}

class _AdabClaimListPageState extends State<AdabClaimListPage> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F7A5C),
        elevation: 0,
        title: const Text(
          'Co-curriculum Claims',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<CoCurriculumClaimModel>>(
        future: controller.getAllPendingClaims(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to retrieve co-curriculum claims.',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          final claims = snapshot.data ?? [];

          if (claims.isEmpty) {
            return _buildEmptyClaimCard();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];

                return _buildClaimCard(claim);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyClaimCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Color(0xFF6B7280),
              ),
              SizedBox(height: 14),
              Text(
                'No Pending Claims',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'There are no co-curriculum claims waiting for verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(CoCurriculumClaimModel claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdabClaimDetailPage(
                claim: claim,
                staff_id: widget.staff_id,
              ),
            ),
          ).then((value) {
            setState(() {});
          });
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFFF3E0),
              child: const Icon(
                Icons.hourglass_top,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student ID: ${claim.student_id}',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Completed Modules: ${claim.completed_module_count} / 4',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Status: ${claim.claim_status}',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}