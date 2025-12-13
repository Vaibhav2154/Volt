import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => [];
}

class RequestSmsPermissionEvent extends SmsEvent {}

class CheckSmsPermissionEvent extends SmsEvent {}

class LoadTransactionsEvent extends SmsEvent {
  final int? limit;

  const LoadTransactionsEvent({this.limit});

  @override
  List<Object?> get props => [limit];
}

class RefreshTransactionsEvent extends SmsEvent {}

class StartListeningToIncomingSmsEvent extends SmsEvent {}

class StopListeningToIncomingSmsEvent extends SmsEvent {}

class NewIncomingTransactionEvent extends SmsEvent {
  final dynamic transaction;
  
  const NewIncomingTransactionEvent(this.transaction);
  
  @override
  List<Object?> get props => [transaction];
}

class SyncTransactionsEvent extends SmsEvent {
  final int userId;
  final List<Transaction> transactions;

  const SyncTransactionsEvent({
    required this.userId,
    required this.transactions,
  });

  @override
  List<Object?> get props => [userId, transactions];
}
