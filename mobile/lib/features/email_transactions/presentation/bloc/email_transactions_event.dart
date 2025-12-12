import 'package:equatable/equatable.dart';

abstract class EmailTransactionsEvent extends Equatable {
  const EmailTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class GetQueueStatsEvent extends EmailTransactionsEvent {
  final String token;

  const GetQueueStatsEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class GetJobStatusEvent extends EmailTransactionsEvent {
  final String jobId;
  final String token;

  const GetJobStatusEvent({
    required this.jobId,
    required this.token,
  });

  @override
  List<Object?> get props => [jobId, token];
}

class EnqueueManualEmailEvent extends EmailTransactionsEvent {
  final String sender;
  final String subject;
  final String body;
  final String token;

  const EnqueueManualEmailEvent({
    required this.sender,
    required this.subject,
    required this.body,
    required this.token,
  });

  @override
  List<Object?> get props => [sender, subject, body, token];
}

class GetRecentTransactionsEvent extends EmailTransactionsEvent {
  final String token;
  final int limit;

  const GetRecentTransactionsEvent({
    required this.token,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [token, limit];
}

class GetTransactionsByBankEvent extends EmailTransactionsEvent {
  final String bankName;
  final String token;
  final int limit;

  const GetTransactionsByBankEvent({
    required this.bankName,
    required this.token,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [bankName, token, limit];
}

class GetHealthStatusEvent extends EmailTransactionsEvent {
  final String token;

  const GetHealthStatusEvent({required this.token});

  @override
  List<Object?> get props => [token];
}





