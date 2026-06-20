import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/manage-login/auth_route_guard.dart';
import 'package:sams/theme/sams_theme.dart';

/// [PaymentRejectionForm] is a Treasury-exclusive page for providing justification
/// when a student's payment submission is declined.
class PaymentRejectionForm extends StatelessWidget {
  final String invoiceNo;

  const PaymentRejectionForm({super.key, required this.invoiceNo});

  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(
      allowedRoles: [UserModel.roleTreasury],
      child: _PaymentRejectionFormView(invoiceNo: invoiceNo),
    );
  }
}

class _PaymentRejectionFormView extends StatefulWidget {
  final String invoiceNo;

  const _PaymentRejectionFormView({required this.invoiceNo});

  @override
  State<_PaymentRejectionFormView> createState() => _PaymentRejectionFormViewState();
}

class _PaymentRejectionFormViewState extends State<_PaymentRejectionFormView> {
  final _formKey = GlobalKey<FormState>();
  
  /// Controller for the rejection reason text area.
  final _reasonController = TextEditingController();
  
  /// Holds any validation errors related to the reason input.
  String? _validationError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load payment details to show the summary to the officer.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PaymentController>().getDetails(widget.invoiceNo);
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Saves the rejection status and reason to Firestore.
  Future<void> onConfirmReject(String invoiceNo) async {
    final reason = _reasonController.text.trim();

    // Ensure the officer has provided a reason.
    if (reason.isEmpty) {
      setState(() {
        _validationError = 'Please provide a reason for the rejection.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final auth = context.read<AuthController>();
    final verifierId = auth.currentUser?.userId ?? 'Unknown';
    final controller = context.read<PaymentController>();
    
    // Update the database record
    await controller.updateStatus(invoiceNo, PaymentModel.statusRejected, reason, verifierId);

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment rejected successfully.')),
    );

    // Pop back to the main management list.
    if (mounted) {
      Navigator.of(context).pop(); // Pops RejectionForm
      Navigator.of(context).pop(); // Pops PaymentVerification
    }
  }

  /// Closes the form without taking action.
  void onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;

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
                            'Reject Payment',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: payment == null || payment.invoiceNo != widget.invoiceNo
                      ? Center(
                          child: Text(
                            controller.errorMessage ?? 'Payment not found.',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        )
                      : Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              // --- Summary card of the payment being rejected ---
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Summary',
                                      style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    _SummaryRow(label: 'Invoice No', value: payment.invoiceNo),
                                    _SummaryRow(label: 'Student ID', value: payment.studentId),
                                    _SummaryRow(label: 'Amount', value: 'RM ${payment.amount.toStringAsFixed(2)}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // --- Rejection reason input field ---
                              const Text(
                                'Reason for Rejection',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _reasonController,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter reason here...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  fillColor: Colors.white.withOpacity(0.05),
                                  filled: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                  errorText: _validationError,
                                ),
                                onChanged: (_) {
                                  if (_validationError != null) {
                                    setState(() {
                                      _validationError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 40),
                              // Primary action button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => onConfirmReject(widget.invoiceNo),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Confirm Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Secondary action button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: onCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
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

/// Helper widget to build summary rows within the rejection form.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
