import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class SmsState extends Equatable {
  const SmsState();

  @override
  List<Object?> get props => [];
}

class SmsInitial extends SmsState {}

class SmsLoading extends SmsState {}

class SmsPermissionDenied extends SmsState {}

class SmsTransactionsLoaded extends SmsState {
  final List<Transaction> transactions;

  const SmsTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class SmsError extends SmsState {
  final String message;

  const SmsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SmsListening extends SmsState {
  final List<Transaction> transactions;

  const SmsListening(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class SmsSyncing extends SmsState {
  final List<Transaction> transactions;

  const SmsSyncing(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class SmsSynced extends SmsState {
  final List<Transaction> transactions;
  final int syncedCount;

  const SmsSynced({
    required this.transactions,
    required this.syncedCount,
  });

  @override
  List<Object?> get props => [transactions, syncedCount];
}
