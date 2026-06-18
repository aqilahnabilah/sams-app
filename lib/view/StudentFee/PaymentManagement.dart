import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/manage-login/auth_route_guard.dart';
import 'package:sams/view/manage-login/login_page.dart';
import 'package:sams/view/StudentFee/PaymentVerification.dart';
import 'package:sams/theme/sams_theme.dart';

/// [PaymentManagement] is the primary dashboard for Treasury Officers.
/// It displays a list of all payment submissions from students and allows filtering by status.
class PaymentManagement extends StatelessWidget {
  const PaymentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleTreasury],
      child: _PaymentManagementView(),
    );
  }
}

class _PaymentManagementView extends StatefulWidget {
  const _PaymentManagementView();

  @override
  State<_PaymentManagementView> createState() => _PaymentManagementViewState();
}

class _PaymentManagementViewState extends State<_PaymentManagementView> {
  /// Currently selected status filter for the list.
  String _statusFilter = 'All';
  
  /// The master list of all payment records fetched from the database.
  List<PaymentModel> _allPayments = [];

  /// Available options for the status filter dropdown.
  static const List<String> _filterOptions = [
    'All',
    PaymentModel.statusPending,
    PaymentModel.statusApproved,
    PaymentModel.statusRejected,
  ];

  @override
  void initState() {
    super.initState();
    // Load initial payment data on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  /// Triggers the controller to fetch the latest payment records.
  Future<void> _loadPayments() async {
    final payments = await context.read<PaymentController>().getAllPayments();
    if (mounted) {
      setState(() {
        _allPayments = payments;
      });
    }
  }

  /// Navigates to the verification screen for a specific selected payment.
  void onSelectPayment(String invoiceNo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentVerification(invoiceNo: invoiceNo)),
    ).then((_) => _loadPayments()); // Refresh list when returning from verification
  }

  /// Returns a filtered subset of [_allPayments] based on the selected [_statusFilter].
  List<PaymentModel> getFilteredList() {
    if (_statusFilter == 'All') return _allPayments;
    return _allPayments.where((payment) => payment.status == _statusFilter).toList();
  }

  /// Logs the user out and returns to the entry screen.
  void _handleLogout() {
    context.read<AuthController>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredList();

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
              // Custom Header row
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
                        'Payment Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
              // Dropdown Filter Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF203A43),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.tealAccent),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: _filterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ),
              // Scrollable List View
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadPayments(),
                  child: filtered.isEmpty
                      ? const Center(child: Text('No payments found.', style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onTap: () => onSelectPayment(p.invoiceNo),
                                title: Text(
                                  p.invoiceNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                subtitle: Text(
                                  'ID: ${p.studentId} | RM ${p.amount.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                ),
                                trailing: _StatusBadge(status: p.status),
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

/// Stylized badge to indicate the current status of a payment submission.
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
