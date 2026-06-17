import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/screens/manage-login/auth_route_guard.dart';
import 'package:sams/view/StudentFee/PaymentRejectionForm.dart';
import 'package:sams/theme/sams_theme.dart';

/// [PaymentVerification] provides a detailed view of a student's payment submission for Treasury Officers.
/// It allows the officer to view the uploaded receipt and either approve or initiate the rejection process.
class PaymentVerification extends StatelessWidget {
  final String invoiceNo;
  const PaymentVerification({super.key, required this.invoiceNo});
  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(allowedRoles: [UserModel.roleTreasury], child: _PaymentVerificationView(invoiceNo: invoiceNo));
  }
}

class _PaymentVerificationView extends StatefulWidget {
  final String invoiceNo;
  const _PaymentVerificationView({required this.invoiceNo});
  @override
  State<_PaymentVerificationView> createState() => _PaymentVerificationViewState();
}

class _PaymentVerificationViewState extends State<_PaymentVerificationView> {
  /// Internal state to track initial data loading.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch detailed data for the specific invoice and student record on load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  /// Coordinates fetching payment details and student fee status from Firestore.
  Future<void> _loadData() async {
    final controller = context.read<PaymentController>();
    await controller.getDetails(widget.invoiceNo);
    if (controller.payment != null) await controller.fetchFeeDetails(controller.payment!.studentId);
    if (mounted) setState(() => _isLoading = false);
  }

  /// Updates the payment status to 'Approved' in the database.
  Future<void> onUpdateStatus(String invoiceNo) async {
    final auth = context.read<AuthController>();
    final controller = context.read<PaymentController>();
    await controller.updateStatus(invoiceNo, PaymentModel.statusApproved, '', auth.currentUser?.userId ?? 'Unknown');
    if (mounted) Navigator.of(context).pop();
  }

  /// Reconstructs the Base64 receipt data and opens it using the system default application.
  Future<void> onViewReceipt() async {
    final controller = context.read<PaymentController>();
    final payment = controller.payment;
    
    if (payment != null && payment.receiptUpload.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );

      await controller.saveAndOpenFile(payment.receiptUpload, 'receipt_${payment.invoiceNo}');
      
      if (mounted) Navigator.pop(context);

      if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No receipt file found.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;
        if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
        if (payment == null) return const Scaffold(body: Center(child: Text('Payment not found.', style: TextStyle(color: Colors.white70))));

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
                  // Custom AppBar with back navigation
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
                            'Verify Payment',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main data view
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _infoCard('Student ID', payment.studentId),
                        _infoCard('Invoice Number', payment.invoiceNo),
                        _infoCard('Amount Paid', 'RM ${payment.amount.toStringAsFixed(2)}'),
                        _infoCard('Payment Method', payment.paymentMethod),
                        _infoCard('Reference Number', payment.refNo.isEmpty ? '-' : payment.refNo),
                        _infoCard('Payment Date', payment.dateCreated),
                        _infoCard(
                          'Status', 
                          payment.status, 
                          valueColor: payment.status == PaymentModel.statusApproved 
                            ? Colors.greenAccent 
                            : (payment.status == PaymentModel.statusRejected ? Colors.redAccent : Colors.amberAccent)
                        ),
                        // Display rejection reason if applicable
                        if (payment.status == PaymentModel.statusRejected)
                          _infoCard('Rejection Reason', payment.rejectionReason),
                          
                        const SizedBox(height: 32),
                        const Text('Receipt Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 16),
                        // Action button to open the PDF/Image receipt
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: onViewReceipt,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('VIEW RECEIPT', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Treasury controls visible only for pending payments
                  if (payment.status == PaymentModel.statusPending)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity, 
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => onUpdateStatus(payment.invoiceNo), 
                              icon: const Icon(Icons.check_circle),
                              label: const Text('APPROVE PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700, 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            )
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, 
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentRejectionForm(invoiceNo: payment.invoiceNo))), 
                              icon: const Icon(Icons.cancel),
                              label: const Text('REJECT PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.shade700, 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            )
                          ),
                        ],
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

  /// Builds a stylized card to display a label-value pair.
  /// Uses [Expanded] to prevent text overflow for long values.
  Widget _infoCard(String label, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
