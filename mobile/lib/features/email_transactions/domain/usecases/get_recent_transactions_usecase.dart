import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../transactions/domain/entities/transaction.dart' as transaction_entity;
import '../repositories/email_transactions_repository.dart';

class GetRecentTransactionsUseCase
    implements UseCase<List<transaction_entity.TransactionEntity>, GetRecentTransactionsParams> {
  final EmailTransactionsRepository repository;

  GetRecentTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<transaction_entity.TransactionEntity>>> call(
      GetRecentTransactionsParams params) async {
    return await repository.getRecentTransactions(
      token: params.token,
      limit: params.limit,
    );
  }
}

class GetRecentTransactionsParams {
  final String token;
  final int limit;

  GetRecentTransactionsParams({
    required this.token,
    this.limit = 20,
  });
}

