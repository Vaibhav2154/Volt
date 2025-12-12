import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/api_constants.dart';
import 'core/network/network_info.dart';
import 'core/services/parsers/bank_parser_factory.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/sms/data/datasources/sms_data_source.dart';
import 'features/sms/data/repositories/sms_repository_impl.dart';
import 'features/sms/domain/repositories/sms_repository.dart';
import 'features/sms/domain/usecases/get_all_transactions_usecase.dart';
import 'features/sms/domain/usecases/has_sms_permissions_usecase.dart';
import 'features/sms/domain/usecases/request_sms_permissions_usecase.dart';
import 'features/sms/presentation/bloc/sms_bloc.dart';
import 'features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'features/transactions/data/datasources/ocr_remote_data_source.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'features/transactions/domain/usecases/extract_transaction_from_image_usecase.dart';
import 'features/transactions/domain/usecases/get_transaction_usecase.dart';
import 'features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/email_config/data/datasources/email_config_remote_data_source.dart';
import 'features/email_config/data/repositories/email_config_repository_impl.dart';
import 'features/email_config/domain/repositories/email_config_repository.dart';
import 'features/email_config/domain/usecases/disable_email_parsing_usecase.dart';
import 'features/email_config/domain/usecases/get_email_parsing_status_usecase.dart';
import 'features/email_config/domain/usecases/setup_app_password_usecase.dart';
import 'features/email_config/domain/usecases/update_app_password_usecase.dart';
import 'features/email_config/presentation/bloc/email_config_bloc.dart';
import 'features/email_transactions/data/datasources/email_transactions_remote_data_source.dart';
import 'features/email_transactions/data/repositories/email_transactions_repository_impl.dart';
import 'features/email_transactions/domain/repositories/email_transactions_repository.dart';
import 'features/email_transactions/domain/usecases/enqueue_manual_email_usecase.dart';
import 'features/email_transactions/domain/usecases/get_health_status_usecase.dart';
import 'features/email_transactions/domain/usecases/get_job_status_usecase.dart';
import 'features/email_transactions/domain/usecases/get_queue_stats_usecase.dart';
import 'features/email_transactions/domain/usecases/get_recent_transactions_usecase.dart';
import 'features/email_transactions/domain/usecases/get_transactions_by_bank_usecase.dart';
import 'features/email_transactions/presentation/bloc/email_transactions_bloc.dart';
import 'features/lean_week/data/datasources/lean_week_remote_data_source.dart';
import 'features/lean_week/data/repositories/lean_week_repository_impl.dart';
import 'features/lean_week/domain/repositories/lean_week_repository.dart';
import 'features/lean_week/domain/usecases/get_cash_flow_forecast_usecase.dart';
import 'features/lean_week/domain/usecases/get_income_smoothing_recommendations_usecase.dart';
import 'features/lean_week/domain/usecases/get_lean_week_analysis_usecase.dart';
import 'features/lean_week/presentation/bloc/lean_week_bloc.dart';
import 'features/goals/data/datasources/goal_remote_data_source.dart';
import 'features/goals/data/repositories/goal_repository_impl.dart';
import 'features/goals/domain/repositories/goal_repository.dart';
import 'features/goals/domain/usecases/goal_usecases.dart';
import 'features/goals/presentation/bloc/goal_bloc.dart';
import 'features/simulations/data/datasources/simulation_remote_data_source.dart';
import 'features/simulations/data/repositories/simulation_repository_impl.dart';
import 'features/simulations/domain/repositories/simulation_repository.dart';
import 'features/simulations/domain/usecases/compare_scenarios_usecase.dart';
import 'features/simulations/domain/usecases/project_future_spending_usecase.dart';
import 'features/simulations/domain/usecases/simulate_reallocation_usecase.dart';
import 'features/simulations/domain/usecases/simulate_spending_enhanced_usecase.dart';
import 'features/simulations/domain/usecases/simulate_spending_usecase.dart';
import 'features/simulations/presentation/bloc/simulation_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
      },
    ),
  );

  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ),
  );

  sl.registerLazySingleton(() => dio);

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  
  // Bank parser factory for SMS parsing
  sl.registerLazySingleton(() => BankParserFactory());

  // Auth feature
  _initAuth();

  // SMS feature
  _initSms();

  // Transactions feature
  _initTransactions();

  // Email Config feature
  _initEmailConfig();

  // Email Transactions feature
  _initEmailTransactions();

  // Lean Week feature
  _initLeanWeek();

  // Goals feature
  _initGoals();

  // Simulations feature
  _initSimulations();
}

void _initAuth() {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl(),
      sharedPreferences: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      isAuthenticatedUseCase: sl(),
    ),
  );
}

void _initSms() {
  // Data sources
  sl.registerLazySingleton<SmsDataSource>(
    () => SmsDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<SmsRepository>(
    () => SmsRepositoryImpl(
      dataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RequestSmsPermissionsUseCase(sl()));
  sl.registerLazySingleton(() => HasSmsPermissionsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTransactionsUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => SmsBloc(
      requestSmsPermissionsUseCase: sl(),
      hasSmsPermissionsUseCase: sl(),
      getAllTransactionsUseCase: sl(),
    ),
  );
}

void _initTransactions() {
  // Data sources
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<OCRRemoteDataSource>(
    () => OCRRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: sl(),
      ocrRemoteDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionUseCase(sl()));
  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => ExtractTransactionFromImageUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => TransactionBloc(
      getTransactionsUseCase: sl(),
      getTransactionsByDateRangeUseCase: sl(),
      getTransactionUseCase: sl(),
      createTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
      extractTransactionFromImageUseCase: sl(),
    ),
  );
}

void _initEmailConfig() {
  // Data sources
  sl.registerLazySingleton<EmailConfigRemoteDataSource>(
    () => EmailConfigRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<EmailConfigRepository>(
    () => EmailConfigRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SetupAppPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GetEmailParsingStatusUseCase(sl()));
  sl.registerLazySingleton(() => DisableEmailParsingUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppPasswordUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => EmailConfigBloc(
      setupAppPasswordUseCase: sl(),
      getEmailParsingStatusUseCase: sl(),
      disableEmailParsingUseCase: sl(),
      updateAppPasswordUseCase: sl(),
    ),
  );
}

void _initEmailTransactions() {
  // Data sources
  sl.registerLazySingleton<EmailTransactionsRemoteDataSource>(
    () => EmailTransactionsRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<EmailTransactionsRepository>(
    () => EmailTransactionsRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetQueueStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetJobStatusUseCase(sl()));
  sl.registerLazySingleton(() => EnqueueManualEmailUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByBankUseCase(sl()));
  sl.registerLazySingleton(() => GetHealthStatusUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => EmailTransactionsBloc(
      getQueueStatsUseCase: sl(),
      getJobStatusUseCase: sl(),
      enqueueManualEmailUseCase: sl(),
      getRecentTransactionsUseCase: sl(),
      getTransactionsByBankUseCase: sl(),
      getHealthStatusUseCase: sl(),
    ),
  );
}

void _initLeanWeek() {
  // Data sources
  sl.registerLazySingleton<LeanWeekRemoteDataSource>(
    () => LeanWeekRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<LeanWeekRepository>(
    () => LeanWeekRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetLeanWeekAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => GetCashFlowForecastUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomeSmoothingRecommendationsUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => LeanWeekBloc(
      getLeanWeekAnalysisUseCase: sl(),
      getCashFlowForecastUseCase: sl(),
      getIncomeSmoothingRecommendationsUseCase: sl(),
    ),
  );
}

void _initGoals() {
  // Data sources
  sl.registerLazySingleton<GoalRemoteDataSource>(
    () => GoalRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => GetAllGoalsUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalsWithProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalUseCase(sl()));
  sl.registerLazySingleton(() => UpdateGoalUseCase(sl()));
  sl.registerLazySingleton(() => DeleteGoalUseCase(sl()));
  sl.registerLazySingleton(() => ActivateGoalUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateGoalUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalContributionsUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => GoalBloc(
      createGoalUseCase: sl(),
      getAllGoalsUseCase: sl(),
      getGoalsWithProgressUseCase: sl(),
      getGoalUseCase: sl(),
      updateGoalUseCase: sl(),
      deleteGoalUseCase: sl(),
      activateGoalUseCase: sl(),
      deactivateGoalUseCase: sl(),
      getGoalContributionsUseCase: sl(),
    ),
  );
}

void _initSimulations() {
  // Data sources
  sl.registerLazySingleton<SimulationRemoteDataSource>(
    () => SimulationRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<SimulationRepository>(
    () => SimulationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SimulateSpendingUseCase(sl()));
  sl.registerLazySingleton(() => SimulateSpendingEnhancedUseCase(sl()));
  sl.registerLazySingleton(() => CompareScenariosUseCase(sl()));
  sl.registerLazySingleton(() => SimulateReallocationUseCase(sl()));
  sl.registerLazySingleton(() => ProjectFutureSpendingUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => SimulationBloc(
      simulateSpendingUseCase: sl(),
      simulateSpendingEnhancedUseCase: sl(),
      compareScenariosUseCase: sl(),
      simulateReallocationUseCase: sl(),
      projectFutureSpendingUseCase: sl(),
    ),
  );
}
