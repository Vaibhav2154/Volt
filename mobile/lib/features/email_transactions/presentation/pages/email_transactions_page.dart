import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../../transactions/presentation/widgets/transaction_card.dart';
import '../bloc/email_transactions_bloc.dart';
import '../bloc/email_transactions_event.dart';
import '../bloc/email_transactions_state.dart';

class EmailTransactionsPage extends StatefulWidget {
  const EmailTransactionsPage({super.key});

  @override
  State<EmailTransactionsPage> createState() => _EmailTransactionsPageState();
}

class _EmailTransactionsPageState extends State<EmailTransactionsPage> {
  String? _token;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final token = await authLocalDataSource.getToken();
    setState(() {
      _token = token;
    });
    if (_token != null) {
      _loadData();
    }
  }

  void _loadData() {
    if (_token == null) return;
    final bloc = context.read<EmailTransactionsBloc>();
    switch (_selectedTab) {
      case 0:
        bloc.add(GetRecentTransactionsEvent(token: _token!, limit: 50));
        break;
      case 1:
        bloc.add(GetQueueStatsEvent(token: _token!));
        break;
      case 2:
        bloc.add(GetHealthStatusEvent(token: _token!));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Email Transactions',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
              _loadData();
            },
            tabs: const [
              Tab(text: 'Recent', icon: Icon(Icons.history)),
              Tab(text: 'Queue Stats', icon: Icon(Icons.analytics)),
              Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
            ],
          ),
        ),
        body: BlocConsumer<EmailTransactionsBloc, EmailTransactionsState>(
          listener: (context, state) {
            if (state is EmailTransactionsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is EmailTransactionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                // Recent Transactions Tab
                _buildRecentTransactionsTab(context, state, theme),
                // Queue Stats Tab
                _buildQueueStatsTab(context, state, theme),
                // Health Tab
                _buildHealthTab(context, state, theme),
              ],
            );
          },
        ),
        floatingActionButton: _selectedTab == 0 && _token != null
            ? FloatingActionButton.extended(
                heroTag: 'email_transactions_fab',
                onPressed: () => _showManualEmailDialog(context),
                icon: const Icon(Icons.email),
                label: const Text('Process Email'),
              )
            : null,
      ),
    );
  }

  Widget _buildRecentTransactionsTab(
    BuildContext context,
    EmailTransactionsState state,
    ThemeData theme,
  ) {
    // Show loading or initial state
    if (state is EmailTransactionsInitial || state is EmailTransactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is RecentTransactionsLoaded) {
      if (state.transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No email transactions found',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (_token != null) {
            context.read<EmailTransactionsBloc>().add(
                  GetRecentTransactionsEvent(token: _token!, limit: 50),
                );
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.transactions.length,
          itemBuilder: (context, index) {
            final transaction = state.transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionCard(transaction: transaction),
            );
          },
        ),
      );
    }

    if (state is EmailTransactionsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildQueueStatsTab(
    BuildContext context,
    EmailTransactionsState state,
    ThemeData theme,
  ) {
    // Show loading or initial state
    if (state is EmailTransactionsInitial || state is EmailTransactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is QueueStatsLoaded) {
      final stats = state.stats;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Queue Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            _buildStatCard(
              context,
              theme,
              'Queued',
              stats.queued.toString(),
              Icons.queue,
              ColorPalette.info,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              theme,
              'Processing',
              stats.processing.toString(),
              Icons.sync,
              ColorPalette.warning,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              theme,
              'Failed',
              stats.failed.toString(),
              Icons.error_outline,
              ColorPalette.error,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _token != null
                    ? () {
                        context.read<EmailTransactionsBloc>().add(
                              GetQueueStatsEvent(token: _token!),
                            );
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is EmailTransactionsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildHealthTab(
    BuildContext context,
    EmailTransactionsState state,
    ThemeData theme,
  ) {
    // Show loading or initial state
    if (state is EmailTransactionsInitial || state is EmailTransactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is HealthStatusLoaded) {
      final health = state.healthStatus;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: health.status == 'healthy'
                      ? [
                          ColorPalette.success.withOpacity(0.15),
                          ColorPalette.success.withOpacity(0.08),
                        ]
                      : [
                          ColorPalette.error.withOpacity(0.15),
                          ColorPalette.error.withOpacity(0.08),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: health.status == 'healthy'
                      ? ColorPalette.success.withOpacity(0.3)
                      : ColorPalette.error.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    health.status == 'healthy'
                        ? Icons.check_circle
                        : Icons.error,
                    color: health.status == 'healthy' ? ColorPalette.success : ColorPalette.error,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${health.status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Redis: ${health.redisConnected ? "Connected" : "Disconnected"}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Timestamp: ${health.timestamp}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Queue Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              theme,
              'Queued',
              health.queueStats.queued.toString(),
              Icons.queue,
              ColorPalette.info,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              theme,
              'Processing',
              health.queueStats.processing.toString(),
              Icons.sync,
              ColorPalette.warning,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              theme,
              'Failed',
              health.queueStats.failed.toString(),
              Icons.error_outline,
              ColorPalette.error,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _token != null
                    ? () {
                        context.read<EmailTransactionsBloc>().add(
                              GetHealthStatusEvent(token: _token!),
                            );
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Health'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is EmailTransactionsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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

  void _showManualEmailDialog(BuildContext context) {
    final senderController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Email Manually'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senderController,
                decoration: const InputDecoration(
                  labelText: 'Sender Email',
                  hintText: 'noreply@bank.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Transaction Alert',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Email Body',
                  hintText: 'Enter email content...',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_token != null &&
                  senderController.text.isNotEmpty &&
                  subjectController.text.isNotEmpty &&
                  bodyController.text.isNotEmpty) {
                context.read<EmailTransactionsBloc>().add(
                      EnqueueManualEmailEvent(
                        sender: senderController.text,
                        subject: subjectController.text,
                        body: bodyController.text,
                        token: _token!,
                      ),
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email enqueued for processing'),
                  ),
                );
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }
}

