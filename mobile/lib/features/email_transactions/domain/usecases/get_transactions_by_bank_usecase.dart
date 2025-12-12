import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../transactions/domain/entities/transaction.dart' as transaction_entity;
import '../repositories/email_transactions_repository.dart';

class GetTransactionsByBankUseCase
    implements UseCase<List<transaction_entity.TransactionEntity>, GetTransactionsByBankParams> {
  final EmailTransactionsRepository repository;

  GetTransactionsByBankUseCase(this.repository);

  @override
  Future<Either<Failure, List<transaction_entity.TransactionEntity>>> call(
      GetTransactionsByBankParams params) async {
    return await repository.getTransactionsByBank(
      bankName: params.bankName,
      token: params.token,
      limit: params.limit,
    );
  }
}

class GetTransactionsByBankParams {
  final String bankName;
  final String token;
  final int limit;

  GetTransactionsByBankParams({
    required this.bankName,
    required this.token,
    this.limit = 20,
  });
}

