/// [PaymentModel] represents a single fee payment transaction submitted by a student.
/// It contains details about the amount, payment method, receipt evidence, and its current verification status.
class PaymentModel {
  // --- Standard Payment Statuses ---
  /// Initial state when a student submits a payment.
  static const String statusPending = 'Pending';
  /// State after a Treasury Officer has verified and accepted the payment.
  static const String statusApproved = 'Approved';
  /// State when a Treasury Officer has found issues with the payment submission.
  static const String statusRejected = 'Rejected';

  // --- Identity and Linked Records ---
  /// Unique invoice or transaction reference number.
  final String invoiceNo;
  /// Identifier of the [StudentFeeModel] this payment applies to.
  final String feeId;
  /// Identifier of the student who made the payment.
  final String studentId;

  // --- Submission Details ---
  /// The channel used for payment (e.g., Bank Transfer, QR Pay).
  final String paymentMethod;
  /// The unique reference number provided by the bank or payment gateway.
  final String refNo;
  /// Base64 encoded string or file path representing the uploaded receipt image/PDF.
  final String receiptUpload;
  /// The specific currency amount paid in this transaction.
  final double amount;

  // --- Verification and Auditing ---
  /// The current lifecycle state of this payment ([statusPending], [statusApproved], or [statusRejected]).
  final String status;
  /// Explanation provided by the Treasury Officer if the payment is rejected.
  final String rejectionReason;
  /// ID of the Treasury Officer who performed the verification.
  final String verifiedBy;
  /// Timestamp string indicating when the student submitted the record.
  final String dateCreated;

  /// Standard constructor for creating a payment transaction.
  PaymentModel({
    required this.invoiceNo,
    required this.feeId,
    required this.studentId,
    required this.paymentMethod,
    required this.refNo,
    required this.receiptUpload,
    required this.amount,
    required this.status,
    required this.rejectionReason,
    required this.verifiedBy,
    required this.dateCreated,
  });

  /// Converts the [PaymentModel] instance into a [Map] for storage in Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'invoice_no': invoiceNo,
      'fee_id': feeId,
      'student_id': studentId,
      'payment_method': paymentMethod,
      'ref_no': refNo,
      'receipt_upload': receiptUpload,
      'amount': amount,
      'status': status,
      'rejection_reason': rejectionReason,
      'verified_by': verifiedBy,
      'date_created': dateCreated,
    };
  }

  /// Creates a [PaymentModel] instance from a [Map] retrieved from Cloud Firestore.
  /// Safely handles nulls and numeric type conversion.
  factory PaymentModel.fromFirestore(Map<String, dynamic> map) {
    return PaymentModel(
      invoiceNo: map['invoice_no']?.toString() ?? '',
      feeId: map['fee_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      paymentMethod: map['payment_method']?.toString() ?? '',
      refNo: map['ref_no']?.toString() ?? '',
      receiptUpload: map['receipt_upload']?.toString() ?? '',
      amount: _readAmount(map['amount']),
      status: map['status']?.toString() ?? statusPending,
      rejectionReason: map['rejection_reason']?.toString() ?? '',
      verifiedBy: map['verified_by']?.toString() ?? '',
      dateCreated: map['date_created']?.toString() ?? '',
    );
  }

  /// Convenience method to check if the payment was specifically rejected by Treasury.
  bool isRejected() {
    return status == statusRejected;
  }

  /// Helper utility to safely convert Firestore dynamic numeric values into [double].
  static double _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
