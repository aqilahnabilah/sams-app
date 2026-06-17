import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/screens/manage-login/auth_route_guard.dart';
import 'package:sams/screens/manage-login/login_page.dart';
import 'package:sams/view/StudentFee/PaymentForm.dart';
import 'package:sams/view/StudentFee/PaymentHistory.dart';
import 'package:sams/theme/sams_theme.dart';

/// The main entry point for the Student Fee module.
/// Provides an overview of the student's current tuition balance and status.
class StudentFeePage extends StatelessWidget {
  const StudentFeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _StudentFeeView(),
    );
  }
}

class _StudentFeeView extends StatefulWidget {
  const _StudentFeeView();

  @override
  State<_StudentFeeView> createState() => _StudentFeeViewState();
}

class _StudentFeeViewState extends State<_StudentFeeView> {
  @override
  void initState() {
    super.initState();
    // Load student and fee data immediately upon entry.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  /// Triggers the controller to pull fresh data from Firestore.
  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    final controller = context.read<PaymentController>();
    controller.errorMessage = null; 
    final studentId = auth.currentUser?.userId ?? '';
    if (studentId.isNotEmpty) {
      await controller.fetchFeeDetails(studentId);
    }
  }

  /// Logs the user out and returns to the login screen.
  void _handleLogout() {
    context.read<AuthController>().logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    
    return Consumer<PaymentController>(
      builder: (context, paymentCtrl, _) {
        if (paymentCtrl.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
          );
        }

        // Error handling view
        if (paymentCtrl.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error'), backgroundColor: SamsColors.teal, foregroundColor: Colors.white),
            body: Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(paymentCtrl.errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            )),
          );
        }

        final student = paymentCtrl.student;
        final fee = paymentCtrl.fee;
        
        final displayName = student?.fullName ?? auth.currentUser?.username ?? 'Student';
        final displayId = student?.studentId ?? auth.currentUser?.userId ?? '-';
        final totalFee = fee?.totalAmount ?? 860.0;
        final paidAmount = fee?.amountPaid ?? 0.0;
        final balance = fee?.balance ?? 860.0;

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
                  // Custom Header row with Back and Logout buttons
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
                            'Fee Dashboard',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Main Fee Information Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // User Header section of the card
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade400,
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Student Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                        Text(displayId, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  // Financial details section of the card
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        _Row(label: 'Total Fee', value: 'RM ${totalFee.toStringAsFixed(2)}'),
                                        const SizedBox(height: 16),
                                        _Row(label: 'Paid Amount', value: 'RM ${paidAmount.toStringAsFixed(2)}'),
                                        const SizedBox(height: 16),
                                        _Row(label: 'Outstanding Balance', value: 'RM ${balance.toStringAsFixed(2)}', color: Colors.redAccent.shade100, isBold: true),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Alert banner if balance is outstanding (Logic for block policy)
                            if (balance > 0)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                ),
                                child: const Row(children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('Payment Required\nYour academic access is restricted due to unpaid fees after Week 5. Please make payment immediately.', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                                ]),
                              ),
                            const SizedBox(height: 32),
                            // Main CTA buttons
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentForm())),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('Make Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistory())),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.tealAccent,
                                  side: BorderSide(color: Colors.teal.shade400, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('View Payment History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper widget to build consistent rows within the information cards.
class _Row extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isBold;
  const _Row({required this.label, required this.value, this.color = Colors.white, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14))),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: 16,
          ),
        )
      ],
    );
  }
}
