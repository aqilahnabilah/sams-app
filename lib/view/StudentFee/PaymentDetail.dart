import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/manage-login/auth_route_guard.dart';
import 'package:sams/theme/sams_theme.dart';

/// Screen to view the detailed metadata of a specific payment transaction.
/// Typically accessed by students from their history list.
class PaymentDetail extends StatelessWidget {
  final String invoiceNo;
  const PaymentDetail({super.key, required this.invoiceNo});
  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(allowedRoles: [UserModel.roleStudent], child: _PaymentDetailView(invoiceNo: invoiceNo));
  }
}

class _PaymentDetailView extends StatefulWidget {
  final String invoiceNo;
  const _PaymentDetailView({required this.invoiceNo});
  @override
  State<_PaymentDetailView> createState() => _PaymentDetailViewState();
}

class _PaymentDetailViewState extends State<_PaymentDetailView> {
  @override
  void initState() {
    super.initState();
    // Load the specific payment details on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PaymentController>().getDetails(widget.invoiceNo));
  }

  /// Downloads and opens the payment receipt evidence using the controller logic.
  Future<void> onDownloadReceipt() async {
    final controller = context.read<PaymentController>();
    final payment = controller.payment;
    if (payment != null && payment.receiptUpload.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );

      await controller.saveAndOpenFile(payment.receiptUpload, 'receipt_${payment.invoiceNo}');
      
      if (mounted) Navigator.pop(context);

      if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;
        if (payment == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));

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
                  // Custom AppBar
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
                            'Payment Details',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _infoCard('Student ID', payment.studentId),
                        _infoCard('Invoice No', payment.invoiceNo),
                        _infoCard('Amount Paid', 'RM ${payment.amount.toStringAsFixed(2)}'),
                        _infoCard('Payment Method', payment.paymentMethod),
                        _infoCard('Reference No', payment.refNo.isEmpty ? '-' : payment.refNo),
                        _infoCard('Payment Date', payment.dateCreated),
                        _infoCard(
                          'Status', 
                          payment.status, 
                          valueColor: payment.status == PaymentModel.statusApproved 
                            ? Colors.greenAccent 
                            : (payment.status == PaymentModel.statusRejected ? Colors.redAccent : Colors.amberAccent)
                        ),
                        if (payment.status == PaymentModel.statusRejected)
                          _infoCard('Rejection Reason', payment.rejectionReason),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: onDownloadReceipt, 
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
