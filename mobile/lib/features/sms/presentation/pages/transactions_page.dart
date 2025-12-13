import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/sms_bloc.dart';
import '../bloc/sms_event.dart';
import '../bloc/sms_state.dart';
import '../widgets/transaction_card.dart';
import '../widgets/empty_transactions_view.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedDays = 30; // Default to 30 days
  SmsBloc? _smsBloc;

  @override
  void initState() {
    super.initState();
    _smsBloc = context.read<SmsBloc>();
    _smsBloc?.add(CheckSmsPermissionEvent());
    // Start listening for incoming SMS to auto-refresh transactions
    _smsBloc?.add(StartListeningToIncomingSmsEvent());
  }

  @override
  void dispose() {
    // Stop listening when page is disposed
    _smsBloc?.add(StopListeningToIncomingSmsEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocBuilder<SmsBloc, SmsState>(
            builder: (context, state) {
              final hasTransactions = state is SmsTransactionsLoaded && 
                                     state.transactions.isNotEmpty;
              return IconButton(
                icon: Icon(
                  Icons.cloud_upload_outlined,
                  color: hasTransactions 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                tooltip: hasTransactions 
                    ? 'Sync to Database (Auto-sync is active)' 
                    : 'No transactions to sync',
                onPressed: hasTransactions ? () {
                  final currentState = context.read<SmsBloc>().state;
                  if (currentState is SmsTransactionsLoaded && 
                      currentState.transactions.isNotEmpty) {
                    // Get user ID from auth
                    final authBloc = context.read<AuthBloc>();
                    if (authBloc.state is AuthAuthenticated) {
                      final user = (authBloc.state as AuthAuthenticated).user;
                      context.read<SmsBloc>().add(
                        SyncTransactionsEvent(
                          userId: user.id,
                          transactions: currentState.transactions,
                        ),
                      );
                    }
                  }
                } : null,
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<SmsBloc>().add(RefreshTransactionsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<SmsBloc, SmsState>(
        listener: (context, state) {
          if (state is SmsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is SmsSynced) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Synced ${state.syncedCount} transaction${state.syncedCount != 1 ? 's' : ''} to database'),
                backgroundColor: ColorPalette.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SmsLoading || state is SmsSyncing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    state is SmsSyncing ? 'Syncing transactions...' : 'Loading transactions...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is SmsPermissionDenied) {
            return _buildPermissionDeniedView(context, theme);
          } else if (state is SmsTransactionsLoaded || state is SmsSynced) {
            final transactions = state is SmsTransactionsLoaded 
                ? state.transactions 
                : (state as SmsSynced).transactions;
            if (transactions.isEmpty) {
              return const EmptyTransactionsView();
            }
            return _buildTransactionsList(transactions, theme);
          }

          return const Center(
            child: Text('Checking permissions...'),
          );
        },
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We need SMS permission to read your bank transaction messages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SmsBloc>().add(RequestSmsPermissionEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, ThemeData theme) {
    // Filter transactions by selected date range
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: _selectedDays));
    
    final filteredTransactions = transactions.where((transaction) {
      if (transaction.timestamp == null) return false;
      return transaction.timestamp!.isAfter(cutoffDate);
    }).toList();

    // Calculate summary for filtered transactions
    double totalCredit = 0;
    double totalDebit = 0;
    
    for (var transaction in filteredTransactions) {
      if (transaction.amount != null) {
        final amount = double.tryParse(transaction.amount!) ?? 0;
        if (transaction.type == TransactionType.credit) {
          totalCredit += amount;
        } else if (transaction.type == TransactionType.debit) {
          totalDebit += amount;
        }
      }
    }

    return Column(
      children: [
        _buildDateRangeFilter(theme),
        _buildSummaryCards(totalCredit, totalDebit, filteredTransactions.length, theme),
        Expanded(
          child: filteredTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions in last $_selectedDays days',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<SmsBloc>().add(RefreshTransactionsEvent());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return TransactionCard(transaction: filteredTransactions[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('7 days', 7, theme),
          const SizedBox(width: 8),
          _buildFilterChip('10 days', 10, theme),
          const SizedBox(width: 8),
          _buildFilterChip('30 days', 30, theme),
          const SizedBox(width: 8),
          _buildFilterChip('90 days', 90, theme),
          const SizedBox(width: 8),
          _buildFilterChip('All', 365, theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int days, ThemeData theme) {
    final isSelected = _selectedDays == days;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDays = days;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildSummaryCards(double totalCredit, double totalDebit, int transactionCount, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Transaction count indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '$transactionCount transaction${transactionCount != 1 ? 's' : ''} in last $_selectedDays days',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorPalette.success.withOpacity(0.15),
                        ColorPalette.success.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPalette.success.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorPalette.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: ColorPalette.success,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Received',
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorPalette.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${totalCredit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorPalette.error.withOpacity(0.15),
                        ColorPalette.error.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPalette.error.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorPalette.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: ColorPalette.error,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sent',
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorPalette.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${totalDebit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
