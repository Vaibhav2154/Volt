import 'package:equatable/equatable.dart';

class ManualEmailJobResponse extends Equatable {
  final String message;
  final String jobId;
  final TransactionPreview? transactionPreview;

  const ManualEmailJobResponse({
    required this.message,
    required this.jobId,
    this.transactionPreview,
  });

  @override
  List<Object?> get props => [message, jobId, transactionPreview];
}

class TransactionPreview extends Equatable {
  final double? amount;
  final String? merchant;
  final String? type;
  final String? bank;

  const TransactionPreview({
    this.amount,
    this.merchant,
    this.type,
    this.bank,
  });

  @override
  List<Object?> get props => [amount, merchant, type, bank];
}

