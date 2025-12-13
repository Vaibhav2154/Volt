import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/get_all_transactions_usecase.dart';
import '../../domain/usecases/has_sms_permissions_usecase.dart';
import '../../domain/usecases/request_sms_permissions_usecase.dart';
import '../../domain/usecases/sync_transactions_usecase.dart';
import 'sms_event.dart';
import 'sms_state.dart';

class SmsBloc extends Bloc<SmsEvent, SmsState> {
  final RequestSmsPermissionsUseCase requestSmsPermissionsUseCase;
  final HasSmsPermissionsUseCase hasSmsPermissionsUseCase;
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final SyncTransactionsUseCase syncTransactionsUseCase;
  StreamSubscription? _smsSubscription;

  SmsBloc({
    required this.requestSmsPermissionsUseCase,
    required this.hasSmsPermissionsUseCase,
    required this.getAllTransactionsUseCase,
    required this.syncTransactionsUseCase,
  }) : super(SmsInitial()) {
    on<RequestSmsPermissionEvent>(_onRequestPermission);
    on<CheckSmsPermissionEvent>(_onCheckPermission);
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<RefreshTransactionsEvent>(_onRefreshTransactions);
    on<StartListeningToIncomingSmsEvent>(_onStartListening);
    on<StopListeningToIncomingSmsEvent>(_onStopListening);
    on<NewIncomingTransactionEvent>(_onNewIncomingTransaction);
    on<SyncTransactionsEvent>(_onSyncTransactions);
  }

  Future<void> _onRequestPermission(
    RequestSmsPermissionEvent event,
    Emitter<SmsState> emit,
  ) async {
    final result = await requestSmsPermissionsUseCase(NoParams());

    result.fold(
      (failure) => emit(SmsError(failure.message)),
      (granted) {
        if (granted) {
          // Directly load transactions after permission is granted
          add(const LoadTransactionsEvent());
        } else {
          emit(SmsPermissionDenied());
        }
      },
    );
  }

  Future<void> _onCheckPermission(
    CheckSmsPermissionEvent event,
    Emitter<SmsState> emit,
  ) async {
    emit(SmsLoading());

    final result = await hasSmsPermissionsUseCase(NoParams());

    result.fold(
      (failure) => emit(SmsError(failure.message)),
      (hasPermission) {
        if (hasPermission) {
          add(const LoadTransactionsEvent());
        } else {
          emit(SmsPermissionDenied());
        }
      },
    );
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<SmsState> emit,
  ) async {
    emit(SmsLoading());

    final result = await getAllTransactionsUseCase(
      GetTransactionsParams(limit: event.limit ?? 100),
    );

    result.fold(
      (failure) => emit(SmsError(failure.message)),
      (transactions) async {
        emit(SmsTransactionsLoaded(transactions));
        // Automatically sync transactions to database
        await _autoSyncTransactions(transactions);
      },
    );
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactionsEvent event,
    Emitter<SmsState> emit,
  ) async {
    final result = await getAllTransactionsUseCase(
      const GetTransactionsParams(limit: 100),
    );

    result.fold(
      (failure) => emit(SmsError(failure.message)),
      (transactions) async {
        emit(SmsTransactionsLoaded(transactions));
        // Automatically sync transactions to database
        await _autoSyncTransactions(transactions);
      },
    );
  }

  /// Automatically sync transactions to database in the background
  Future<void> _autoSyncTransactions(List<Transaction> transactions) async {
    if (transactions.isEmpty) return;

    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('⚠️ Cannot auto-sync: User ID not found');
        return;
      }

      // Sync in background (silently, no UI feedback)
      final syncResult = await syncTransactionsUseCase(
        SyncTransactionsParams(
          transactions: transactions,
          userId: userId,
        ),
      );

      syncResult.fold(
        (failure) {
          // Log error but don't show to user (auto-sync is silent)
          print('⚠️ Auto-sync failed: ${failure.message}');
        },
        (syncedTransactions) {
          // Log success silently
          print('✅ Auto-synced ${syncedTransactions.length} transaction(s) to database');
        },
      );
    } catch (e) {
      // Log error but don't interrupt user experience
      print('⚠️ Auto-sync error: $e');
    }
  }

  void _onStartListening(
    StartListeningToIncomingSmsEvent event,
    Emitter<SmsState> emit,
  ) {
    // Auto-refresh will be handled by periodic checks or manual refresh
    // For now, this is a placeholder for future real-time SMS monitoring
  }

  void _onStopListening(
    StopListeningToIncomingSmsEvent event,
    Emitter<SmsState> emit,
  ) {
    _smsSubscription?.cancel();
    _smsSubscription = null;
  }

  Future<void> _onNewIncomingTransaction(
    NewIncomingTransactionEvent event,
    Emitter<SmsState> emit,
  ) async {
    // Refresh transactions when a new SMS arrives
    add(RefreshTransactionsEvent());
  }

  Future<void> _onSyncTransactions(
    SyncTransactionsEvent event,
    Emitter<SmsState> emit,
  ) async {
    // Emit syncing state with current transactions
    if (state is SmsTransactionsLoaded) {
      emit(SmsSyncing((state as SmsTransactionsLoaded).transactions));
    } else {
      emit(SmsSyncing(event.transactions));
    }

    final result = await syncTransactionsUseCase(
      SyncTransactionsParams(
        transactions: event.transactions,
        userId: event.userId,
      ),
    );

    // Check if emit is still valid before emitting
    if (emit.isDone) return;

    result.fold(
      (failure) {
        // On error, go back to loaded state
        if (!emit.isDone) {
          emit(SmsTransactionsLoaded(event.transactions));
        }
        if (!emit.isDone) {
          emit(SmsError('Failed to sync transactions: ${failure.message}'));
        }
      },
      (syncedTransactions) async {
        // Success - emit synced state
        final syncedCount = syncedTransactions.length;
        if (!emit.isDone) {
          emit(SmsSynced(
            transactions: event.transactions,
            syncedCount: syncedCount,
          ));
        }
        // After a short delay, go back to loaded state (only if still valid)
        await Future.delayed(const Duration(seconds: 2));
        if (!emit.isDone && !isClosed) {
          emit(SmsTransactionsLoaded(event.transactions));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _smsSubscription?.cancel();
    return super.close();
  }
}
