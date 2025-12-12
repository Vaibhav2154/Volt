import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/summary_card.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../lean_week/presentation/pages/lean_week_page.dart';
import '../../../lean_week/presentation/bloc/lean_week_bloc.dart';
import '../../../simulations/presentation/pages/simulations_page.dart';
import '../../../simulations/presentation/bloc/simulation_bloc.dart';
import '../../../gamification/presentation/pages/gamification_page.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../init_dependencies.dart';
import '../../../sms/presentation/bloc/sms_bloc.dart';
import '../../../sms/presentation/pages/transactions_page.dart' as sms_transactions;
import '../../../email_config/presentation/bloc/email_config_bloc.dart';
import '../../../email_config/presentation/pages/email_config_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load transactions for summary
    final transactionBloc = context.read<TransactionBloc>();
    transactionBloc.add(const LoadTransactionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const LoadingState(message: 'Loading...');
          }

          final user = authState.user;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(
                    const RefreshTransactionsEvent(),
                  );
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Volt',
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
                        Icons.person_outline,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<GamificationBloc>(),
                              child: const ProfilePage(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Summary section
                        BlocBuilder<TransactionBloc, TransactionState>(
                          builder: (context, state) {
                            if (state is TransactionLoading) {
                              return const SizedBox(
                                height: 120,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (state is TransactionsLoaded) {
                              final transactions = state.transactions;
                              final now = DateTime.now();
                              final monthStart = DateTime(now.year, now.month, 1);
                              
                              final monthTransactions = transactions.where((t) {
                                if (t.timestamp == null) return false;
                                return t.timestamp!.isAfter(monthStart);
                              }).toList();

                              double totalCredit = 0;
                              double totalDebit = 0;

                              for (var t in monthTransactions) {
                                if (t.type == TransactionType.credit) {
                                  totalCredit += t.amount;
                                } else {
                                  totalDebit += t.amount;
                                }
                              }

                              final netFlow = totalCredit - totalDebit;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // First row: Received and Spent
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SummaryCard(
                                            label: 'Received',
                                            amount: totalCredit,
                                            isCredit: true,
                                            icon: Icons.arrow_downward,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SummaryCard(
                                            label: 'Spent',
                                            amount: totalDebit,
                                            isCredit: false,
                                            icon: Icons.arrow_upward,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Second row: Net Flow
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.colorScheme.outline.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Net Flow',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '₹${netFlow.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: netFlow >= 0
                                                      ? ColorPalette.success
                                                      : ColorPalette.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            netFlow >= 0
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color: netFlow >= 0
                                                ? ColorPalette.success
                                                : ColorPalette.error,
                                            size: 32,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 24),
                        // Quick actions
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // First row
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                context,
                                theme,
                                Icons.account_balance_wallet,
                                'Transactions',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => sl<TransactionBloc>(),
                                        child: const TransactionsPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                context,
                                theme,
                                Icons.flag,
                                'Goals',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => sl<GoalBloc>(),
                                        child: const GoalsPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                context,
                                theme,
                                Icons.analytics_outlined,
                                'Lean Week',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => sl<LeanWeekBloc>(),
                                        child: const LeanWeekPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                context,
                                theme,
                                Icons.calculate,
                                'Simulations',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => sl<SimulationBloc>(),
                                        child: const SimulationsPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Third row - Gamification
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                context,
                                theme,
                                Icons.emoji_events,
                                'Achievements',
                                () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => sl<GamificationBloc>(),
                                        child: const GamificationPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(), // Empty space for alignment
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Data sources
                        Text(
                          'Data Sources',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InfoCard(
                          icon: Icons.sms_outlined,
                          title: 'SMS Transactions',
                          description: 'Import from device SMS (Android)',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => sl<SmsBloc>(),
                                  child: const sms_transactions.TransactionsPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        InfoCard(
                          icon: Icons.email_outlined,
                          title: 'Email Parsing',
                          description: 'Configure email transaction parsing',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => sl<EmailConfigBloc>(),
                                  child: const EmailConfigPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: ColorPalette.success,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

