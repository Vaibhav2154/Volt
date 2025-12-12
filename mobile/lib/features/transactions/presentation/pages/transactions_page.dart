import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_card.dart';
import '../widgets/empty_transactions_view.dart';
import '../widgets/transaction_summary_card.dart';
import '../widgets/transaction_form_dialog.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  int _selectedDays = 30;
  late TabController _tabController;
  late final TransactionBloc _transactionBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactionBloc = context.read<TransactionBloc>();
    _transactionBloc.add(const LoadTransactionsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Transactions',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    _transactionBloc.add(
                          const RefreshTransactionsEvent(),
                        );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => _showAddTransactionDialog(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ];
        },
        body: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
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
            } else if (state is TransactionCreated) {
              Navigator.of(context).pop(); // Close form dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Transaction created successfully'),
                  backgroundColor: ColorPalette.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is TransactionUpdated) {
              Navigator.of(context).pop(); // Close form dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Transaction updated successfully'),
                  backgroundColor: ColorPalette.info,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is TransactionDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Transaction deleted successfully'),
                  backgroundColor: ColorPalette.warning,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is TransactionsLoaded) {
              if (state.transactions.isEmpty) {
                return const EmptyTransactionsView();
              }
              return _buildTransactionsList(state.transactions, theme);
            } else if (state is TransactionError) {
              return ErrorState(
                message: state.message,
                onRetry: () {
                  _transactionBloc.add(
                        const LoadTransactionsEvent(),
                      );
                },
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<TransactionEntity> transactions,
    ThemeData theme,
  ) {
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
      if (transaction.type == TransactionType.credit) {
        totalCredit += transaction.amount;
      } else {
        totalDebit += transaction.amount;
      }
    }

    return Column(
      children: [
        _buildDateRangeFilter(theme),
        TransactionSummaryCard(
          totalCredit: totalCredit,
          totalDebit: totalDebit,
          transactionCount: filteredTransactions.length,
          selectedDays: _selectedDays,
        ),
        Expanded(
          child: filteredTransactions.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions',
                  description: 'No transactions found in the last $_selectedDays days',
                  actionLabel: 'Add Transaction',
                  onAction: () => _showAddTransactionDialog(context),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _transactionBloc.add(
                          const RefreshTransactionsEvent(),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return TransactionCard(
                        transaction: filteredTransactions[index],
                        onTap: () => _showTransactionDetails(
                          context,
                          filteredTransactions[index],
                        ),
                        onDelete: () => _confirmDeleteTransaction(
                          context,
                          filteredTransactions[index],
                        ),
                      );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.2),
          width: 1.5,
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    final theme = Theme.of(context);
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? ColorPalette.success : ColorPalette.error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Details',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCredit ? 'CREDIT' : 'DEBIT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Amount
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    // Details
                    if (transaction.merchant != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.store_rounded,
                        label: 'Merchant',
                        value: transaction.merchant!,
                      ),
                    if (transaction.category != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: transaction.category!,
                      ),
                    if (transaction.bankName != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.account_balance_rounded,
                        label: 'Bank',
                        value: transaction.bankName!,
                      ),
                    if (transaction.upiId != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.account_circle_rounded,
                        label: 'UPI ID',
                        value: transaction.upiId!,
                      ),
                    if (transaction.transactionId != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.tag_rounded,
                        label: 'Transaction ID',
                        value: transaction.transactionId!,
                      ),
                    if (transaction.balance != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Available Balance',
                        value: '₹${transaction.balance!.toStringAsFixed(2)}',
                      ),
                    if (transaction.timestamp != null)
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value: _formatDateTime(transaction.timestamp!),
                      ),
                    if (transaction.rawMessage != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        'Original Message',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          transaction.rawMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditTransactionDialog(context, transaction);
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDeleteTransaction(context, transaction);
                            },
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.error,
                              foregroundColor: theme.colorScheme.onError,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showAddTransactionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    int? userId;

    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: _transactionBloc,
        child: TransactionFormDialog(
          userId: userId!,
          onSubmit: ({
            required int userId,
            required double amount,
            required TransactionType type,
            String? merchant,
            String? category,
            String? upiId,
            String? transactionId,
            DateTime? timestamp,
            double? balance,
            String? bankName,
            String? accountNumber,
            String? rawMessage,
          }) {
            _transactionBloc.add(
              CreateTransactionEvent(
                userId: userId,
                amount: amount,
                type: type,
                merchant: merchant,
                category: category,
                upiId: upiId,
                transactionId: transactionId,
                timestamp: timestamp,
                balance: balance,
                bankName: bankName,
                accountNumber: accountNumber,
                rawMessage: rawMessage,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditTransactionDialog(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    final authState = context.read<AuthBloc>().state;
    int? userId;

    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: _transactionBloc,
        child: TransactionFormDialog(
          transaction: transaction,
          userId: userId!,
          onSubmit: ({
            required int userId,
            required double amount,
            required TransactionType type,
            String? merchant,
            String? category,
            String? upiId,
            String? transactionId,
            DateTime? timestamp,
            double? balance,
            String? bankName,
            String? accountNumber,
            String? rawMessage,
          }) {
            _transactionBloc.add(
              UpdateTransactionEvent(
                transactionId: transaction.id,
                userId: userId,
                amount: amount,
                type: type,
                merchant: merchant,
                category: category,
                upiId: upiId,
                transactionReferenceId: transactionId,
                timestamp: timestamp,
                balance: balance,
                bankName: bankName,
                accountNumber: accountNumber,
                rawMessage: rawMessage,
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _transactionBloc.add(
                    DeleteTransactionEvent(transaction.id),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

