import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/screens/manage-login/auth_route_guard.dart';
import 'package:sams/view/StudentFee/PaymentDetail.dart';
import 'package:sams/theme/sams_theme.dart';

/// Screen for students to view their historical payment submissions.
/// Includes real-time filtering by invoice number or status.
class PaymentHistory extends StatelessWidget {
  const PaymentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _PaymentHistoryView(),
    );
  }
}

class _PaymentHistoryView extends StatefulWidget {
  const _PaymentHistoryView();

  @override
  State<_PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<_PaymentHistoryView> {
  String _filterText = '';
  List<PaymentModel> _studentPayments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  /// Fetches the submission list for the currently logged-in student.
  Future<void> _loadPayments() async {
    final auth = context.read<AuthController>();
    final studentId = auth.currentUser?.userId ?? '';
    if (studentId.isNotEmpty) {
      final payments = await context.read<PaymentController>().fetchStudentPayments(studentId);
      if (mounted) {
        setState(() {
          _studentPayments = payments;
        });
      }
    }
  }

  /// Updates the search filter state.
  void handleFilterChange(String query) {
    setState(() {
      _filterText = query;
    });
  }

  /// Navigates to the detailed view of a specific payment.
  void onSelectPayment(String invoiceNo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentDetail(invoiceNo: invoiceNo)),
    );
  }

  /// Filters the local payment list based on user search input.
  List<PaymentModel> getFilteredData() {
    if (_filterText.trim().isEmpty) {
      return _studentPayments;
    }
    final query = _filterText.trim().toLowerCase();
    return _studentPayments.where((payment) {
      return payment.invoiceNo.toLowerCase().contains(query) ||
          payment.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredData();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SamsColors.portalGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Payment History',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Input Field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filter by invoice number or status',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.tealAccent),
                    ),
                  ),
                  onChanged: handleFilterChange,
                ),
              ),
              // Scrollable list of payments
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadPayments(),
                  child: filtered.isEmpty
                      ? const Center(child: Text('No payment records found.', style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final payment = filtered[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onTap: () => onSelectPayment(payment.invoiceNo),
                                title: Text(
                                  payment.invoiceNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Amount: RM ${payment.amount.toStringAsFixed(2)}\nDate: ${payment.dateCreated}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                ),
                                trailing: _StatusBadge(status: payment.status),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stylized badge to indicate the payment verification status.
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case PaymentModel.statusApproved: color = Colors.greenAccent; break;
      case PaymentModel.statusRejected: color = Colors.redAccent; break;
      default: color = Colors.amberAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
