import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/transactions/domain/entities/transaction.dart';
import '../../../../features/transactions/domain/repositories/transaction_repository.dart';
import '../entities/transaction.dart' as sms_transaction;

class SyncTransactionsUseCase implements UseCase<List<TransactionEntity>, SyncTransactionsParams> {
  final TransactionRepository transactionRepository;

  SyncTransactionsUseCase(this.transactionRepository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(SyncTransactionsParams params) async {
    // Convert SMS Transaction entities to transaction data maps
    final transactionDataList = params.transactions.map((smsTransaction) {
      return {
        'user_id': params.userId,
        'amount': smsTransaction.amount != null 
            ? double.tryParse(smsTransaction.amount!) 
            : null,
        'type': smsTransaction.type == sms_transaction.TransactionType.credit ? 'credit' : 'debit',
        if (smsTransaction.merchant != null) 'merchant': smsTransaction.merchant,
        if (smsTransaction.upiId != null) 'upiId': smsTransaction.upiId,
        if (smsTransaction.transactionId != null) 'transactionId': smsTransaction.transactionId,
        if (smsTransaction.timestamp != null) 'timestamp': smsTransaction.timestamp!.toIso8601String(),
        if (smsTransaction.balance != null) 'balance': double.tryParse(smsTransaction.balance!),
        if (smsTransaction.bankName != null) 'bankName': smsTransaction.bankName,
        if (smsTransaction.accountNumber != null) 'accountNumber': smsTransaction.accountNumber,
        if (smsTransaction.rawMessage.isNotEmpty) 'rawMessage': smsTransaction.rawMessage,
      };
    }).toList();

    return await transactionRepository.createBulkTransactions(
      transactions: transactionDataList,
    );
  }
}

class SyncTransactionsParams {
  final List<sms_transaction.Transaction> transactions;
  final int userId;

  SyncTransactionsParams({
    required this.transactions,
    required this.userId,
  });
}

