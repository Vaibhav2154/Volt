import 'package:equatable/equatable.dart';
import '../../domain/entities/email_health_status.dart';
import '../../domain/entities/job_stats.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/entities/manual_email_job_response.dart';
import '../../../transactions/domain/entities/transaction.dart' as transaction_entity;

abstract class EmailTransactionsState extends Equatable {
  const EmailTransactionsState();

  @override
  List<Object?> get props => [];
}

class EmailTransactionsInitial extends EmailTransactionsState {}

class EmailTransactionsLoading extends EmailTransactionsState {}

class QueueStatsLoaded extends EmailTransactionsState {
  final JobStats stats;

  const QueueStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class JobStatusLoaded extends EmailTransactionsState {
  final JobStatus status;

  const JobStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class ManualEmailEnqueued extends EmailTransactionsState {
  final ManualEmailJobResponse response;

  const ManualEmailEnqueued(this.response);

  @override
  List<Object?> get props => [response];
}

class RecentTransactionsLoaded extends EmailTransactionsState {
  final List<transaction_entity.TransactionEntity> transactions;

  const RecentTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionsByBankLoaded extends EmailTransactionsState {
  final List<transaction_entity.TransactionEntity> transactions;

  const TransactionsByBankLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class HealthStatusLoaded extends EmailTransactionsState {
  final EmailHealthStatus healthStatus;

  const HealthStatusLoaded(this.healthStatus);

  @override
  List<Object?> get props => [healthStatus];
}

class EmailTransactionsError extends EmailTransactionsState {
  final String message;

  const EmailTransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

