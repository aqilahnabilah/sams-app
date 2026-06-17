import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/screens/manage-login/auth_route_guard.dart';
import 'package:sams/view/StudentFee/PaymentHistory.dart';
import 'package:sams/theme/sams_theme.dart';

/// Screen for students to submit a new fee payment record.
/// Protected by [AuthRouteGuard] to ensure only students can access.
class PaymentForm extends StatelessWidget {
  const PaymentForm({super.key});
  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _PaymentFormView(),
    );
  }
}

class _PaymentFormView extends StatefulWidget {
  const _PaymentFormView();
  @override
  State<_PaymentFormView> createState() => _PaymentFormViewState();
}

class _PaymentFormViewState extends State<_PaymentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _receiptController = TextEditingController();

  String _invoiceNo = '';
  String _amount = '';
  String _paymentMethod = PaymentController.supportedPaymentMethods.first;
  String _refNo = '';
  String _paymentDate = '';
  File? _selectedFile;

  @override
  void dispose() {
    _dateController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fetch fee details to ensure the linked fee record is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final studentId = auth.currentUser?.userId ?? '';
      if (studentId.isNotEmpty) context.read<PaymentController>().fetchFeeDetails(studentId);
    });
  }

  /// Opens the system date picker with themed styling.
  Future<void> onSelectedDate() async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: DateTime.now(), 
      firstDate: DateTime(2020), 
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF203A43),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _paymentDate = formatted;
        _dateController.text = formatted;
      });
    }
  }

  /// Uses the file picker to select a payment receipt (Image or PDF).
  Future<void> onUploadReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['jpg', 'pdf', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _receiptController.text = result.files.single.name;
      });
    }
  }

  /// Validates and submits the payment data to Firestore via the controller.
  Future<void> submitPayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a receipt.')));
        return;
      }

      final controller = context.read<PaymentController>();
      
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
      
      // Convert file to Base64 for Firestore storage
      final base64String = await controller.fileToBase64(_selectedFile!);
      if (mounted) Navigator.pop(context);

      if (base64String == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'File error.'), backgroundColor: Colors.redAccent));
        return;
      }

      // Create the record
      await controller.createPaymentRecord(_invoiceNo, double.parse(_amount), _refNo, _paymentMethod, _paymentDate, base64String);

      if (controller.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment submitted!')));
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentHistory()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        'Submit Payment',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'Invoice Number',
                          icon: Icons.receipt_outlined,
                          onChanged: (v) => _invoiceNo = v,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Amount',
                          icon: Icons.attach_money,
                          prefixText: 'RM ',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _amount = v,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          dropdownColor: const Color(0xFF203A43),
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(label: 'Payment Method', icon: Icons.payment_outlined),
                          items: PaymentController.supportedPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Reference Number',
                          icon: Icons.tag,
                          onChanged: (v) => _refNo = v,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(label: 'Payment Date', icon: Icons.calendar_today),
                          onTap: onSelectedDate,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _receiptController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(label: 'Receipt File', icon: Icons.upload_file, hint: 'Select file'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onUploadReceipt, 
                            icon: const Icon(Icons.add_photo_alternate_outlined), 
                            label: const Text('UPLOAD RECEIPT', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.tealAccent,
                              side: const BorderSide(color: Colors.tealAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity, 
                          height: 56,
                          child: ElevatedButton(
                            onPressed: submitPayment, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade400, 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ), 
                            child: const Text('Submit Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          )
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
  }

  /// Utility to build consistent styled text fields.
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    String? prefixText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label: label, icon: icon, prefixText: prefixText),
      onChanged: onChanged,
    );
  }

  /// Shared decoration logic for form fields to maintain UI consistency.
  InputDecoration _buildInputDecoration({required String label, required IconData icon, String? prefixText, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
