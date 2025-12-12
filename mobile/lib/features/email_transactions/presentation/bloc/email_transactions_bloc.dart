import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/enqueue_manual_email_usecase.dart';
import '../../domain/usecases/get_health_status_usecase.dart';
import '../../domain/usecases/get_job_status_usecase.dart';
import '../../domain/usecases/get_queue_stats_usecase.dart';
import '../../domain/usecases/get_recent_transactions_usecase.dart';
import '../../domain/usecases/get_transactions_by_bank_usecase.dart';
import 'email_transactions_event.dart';
import 'email_transactions_state.dart';

class EmailTransactionsBloc
    extends Bloc<EmailTransactionsEvent, EmailTransactionsState> {
  final GetQueueStatsUseCase getQueueStatsUseCase;
  final GetJobStatusUseCase getJobStatusUseCase;
  final EnqueueManualEmailUseCase enqueueManualEmailUseCase;
  final GetRecentTransactionsUseCase getRecentTransactionsUseCase;
  final GetTransactionsByBankUseCase getTransactionsByBankUseCase;
  final GetHealthStatusUseCase getHealthStatusUseCase;

  EmailTransactionsBloc({
    required this.getQueueStatsUseCase,
    required this.getJobStatusUseCase,
    required this.enqueueManualEmailUseCase,
    required this.getRecentTransactionsUseCase,
    required this.getTransactionsByBankUseCase,
    required this.getHealthStatusUseCase,
  }) : super(EmailTransactionsInitial()) {
    on<GetQueueStatsEvent>(_onGetQueueStats);
    on<GetJobStatusEvent>(_onGetJobStatus);
    on<EnqueueManualEmailEvent>(_onEnqueueManualEmail);
    on<GetRecentTransactionsEvent>(_onGetRecentTransactions);
    on<GetTransactionsByBankEvent>(_onGetTransactionsByBank);
    on<GetHealthStatusEvent>(_onGetHealthStatus);
  }

  Future<void> _onGetQueueStats(
    GetQueueStatsEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await getQueueStatsUseCase(event.token);

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (stats) => emit(QueueStatsLoaded(stats)),
    );
  }

  Future<void> _onGetJobStatus(
    GetJobStatusEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await getJobStatusUseCase(
      GetJobStatusParams(
        jobId: event.jobId,
        token: event.token,
      ),
    );

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (status) => emit(JobStatusLoaded(status)),
    );
  }

  Future<void> _onEnqueueManualEmail(
    EnqueueManualEmailEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await enqueueManualEmailUseCase(
      EnqueueManualEmailParams(
        sender: event.sender,
        subject: event.subject,
        body: event.body,
        token: event.token,
      ),
    );

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (response) => emit(ManualEmailEnqueued(response)),
    );
  }

  Future<void> _onGetRecentTransactions(
    GetRecentTransactionsEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await getRecentTransactionsUseCase(
      GetRecentTransactionsParams(
        token: event.token,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (transactions) => emit(RecentTransactionsLoaded(transactions)),
    );
  }

  Future<void> _onGetTransactionsByBank(
    GetTransactionsByBankEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await getTransactionsByBankUseCase(
      GetTransactionsByBankParams(
        bankName: event.bankName,
        token: event.token,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (transactions) => emit(TransactionsByBankLoaded(transactions)),
    );
  }

  Future<void> _onGetHealthStatus(
    GetHealthStatusEvent event,
    Emitter<EmailTransactionsState> emit,
  ) async {
    emit(EmailTransactionsLoading());

    final result = await getHealthStatusUseCase(event.token);

    result.fold(
      (failure) => emit(EmailTransactionsError(failure.message)),
      (healthStatus) => emit(HealthStatusLoaded(healthStatus)),
    );
  }
}

