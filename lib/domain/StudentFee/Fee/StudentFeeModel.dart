/// [StudentFeeModel] represents the tuition fee structure for a specific student and semester.
/// It tracks the total amount owed, the amount already paid, and the remaining balance.
class StudentFeeModel {
  // --- Fee identity and relationships ---
  /// Unique identifier for the fee record.
  final String feeId;
  /// Identifier of the student associated with this fee.
  final String studentId;
  /// Identifier of the academic semester for which this fee is charged.
  final String semId;

  // --- Financial Amounts ---
  /// The total tuition fee amount for the semester.
  final double totalAmount;
  /// The total amount the student has paid so far.
  final double amountPaid;

  // --- Calculated Logic ---
  /// The remaining balance to be paid. This is typically updated by [calculateBalance].
  double balance;

  // --- Deadlines ---
  /// The final date by which the fee must be settled to avoid student can't seat for final exam.
  final String dueDate;

  /// Standard constructor for initializing a fee record.
  StudentFeeModel({
    required this.feeId,
    required this.studentId,
    required this.semId,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.dueDate,
  });

  /// Converts the [StudentFeeModel] instance into a [Map] for storage in Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'fee_id': feeId,
      'student_id': studentId,
      'sem_id': semId,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'balance': balance,
      'due_date': dueDate,
    };
  }

  /// Creates a [StudentFeeModel] instance from a [Map] retrieved from Cloud Firestore.
  /// It automatically recalculates the balance based on the total and paid amounts.
  factory StudentFeeModel.fromFirestore(Map<String, dynamic> map) {
    final model = StudentFeeModel(
      feeId: map['fee_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      semId: map['sem_id']?.toString() ?? '',
      totalAmount: _readAmount(map['total_amount']),
      amountPaid: _readAmount(map['amount_paid']),
      balance: _readAmount(map['balance']),
      dueDate: map['due_date']?.toString() ?? '',
    );
    model.calculateBalance();
    return model;
  }

  /// Calculates and returns the outstanding [balance].
  /// Balance is defined as [totalAmount] minus [amountPaid].
  double calculateBalance() {
    balance = totalAmount - amountPaid;
    return balance;
  }

  /// Determines if a student's academic access should be blocked.
  /// According to university policy, students are blocked starting from [week] 5
  /// if they still have an outstanding [balance].
  bool isBlocked(int week) {
    calculateBalance();
    return week >= 5 && balance > 0;
  }

  /// Helper utility to safely convert Firestore dynamic numeric values into [double].
  /// Handles both [int] and [double] types.
  static double _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
