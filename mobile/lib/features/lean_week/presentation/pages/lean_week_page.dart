import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/lean_week_bloc.dart';
import '../bloc/lean_week_event.dart';
import '../bloc/lean_week_state.dart';

class LeanWeekPage extends StatefulWidget {
  const LeanWeekPage({super.key});

  @override
  State<LeanWeekPage> createState() => _LeanWeekPageState();
}

class _LeanWeekPageState extends State<LeanWeekPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAnalysis();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Tab change completed, load data for the new tab
      _loadDataForTab(_tabController.index);
    }
  }

  Future<void> _loadDataForTab(int index) async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final token = await authLocalDataSource.getToken();
    if (token == null) return;

    switch (index) {
      case 0:
        _loadAnalysis();
        break;
      case 1:
        context.read<LeanWeekBloc>().add(
              GetCashFlowForecastEvent(token: token),
            );
        break;
      case 2:
        context.read<LeanWeekBloc>().add(
              GetIncomeSmoothingRecommendationsEvent(token: token),
            );
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final authLocalDataSource = sl<AuthLocalDataSource>();
      final token = await authLocalDataSource.getToken();
      if (token != null) {
        context.read<LeanWeekBloc>().add(
              GetLeanWeekAnalysisEvent(token: token),
            );
      }
    }
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

          return BlocConsumer<LeanWeekBloc, LeanWeekState>(
            listener: (context, state) {
              if (state is LeanWeekError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 100,
                      floating: false,
                      pinned: true,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Lean Week Analysis',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(left: 16, bottom: 8),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                          indicatorColor: theme.colorScheme.primary,
                          tabs: const [
                            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                            Tab(text: 'Forecast', icon: Icon(Icons.trending_up)),
                            Tab(text: 'Recommendations', icon: Icon(Icons.lightbulb)),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: _buildTabBarView(context, state),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context, LeanWeekState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTabView(context, state),
        _buildForecastTabView(context, state),
        _buildRecommendationsTabView(context, state),
      ],
    );
  }

  Widget _buildOverviewTabView(BuildContext context, LeanWeekState state) {
    if (state is LeanWeekLoading) {
      return const Center(
        child: LoadingState(message: 'Loading analysis...'),
      );
    }

    if (state is LeanWeekAnalysisLoaded) {
      return _buildOverviewTab(context, state.analysis);
    }

    if (state is LeanWeekError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to load analysis',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalysis,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Load Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTabView(BuildContext context, LeanWeekState state) {
    if (state is LeanWeekLoading) {
      return const Center(
        child: LoadingState(message: 'Loading forecast...'),
      );
    }

    if (state is CashFlowForecastLoaded) {
      return _buildForecastTab(context, state.forecast);
    }

    if (state is LeanWeekError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final authLocalDataSource = sl<AuthLocalDataSource>();
                final token = await authLocalDataSource.getToken();
                if (token != null) {
                  context.read<LeanWeekBloc>().add(
                        GetCashFlowForecastEvent(token: token),
                      );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to load forecast',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTabView(BuildContext context, LeanWeekState state) {
    if (state is LeanWeekLoading) {
      return const Center(
        child: LoadingState(message: 'Loading recommendations...'),
      );
    }

    if (state is IncomeSmoothingRecommendationsLoaded) {
      return _buildRecommendationsTab(context, state.recommendations);
    }

    if (state is LeanWeekError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final authLocalDataSource = sl<AuthLocalDataSource>();
                final token = await authLocalDataSource.getToken();
                if (token != null) {
                  context.read<LeanWeekBloc>().add(
                        GetIncomeSmoothingRecommendationsEvent(token: token),
                      );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to load recommendations',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, analysis) {
    final theme = Theme.of(context);
    final summary = analysis.summary;
    final riskColor = _getRiskColor(summary.riskLevel, theme);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Risk Summary Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: riskColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getRiskIcon(summary.riskLevel),
                          color: riskColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Risk Level: ${summary.riskLevel}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.riskMessage,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (summary.immediateActionNeeded) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Immediate action required',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Historical Analysis
              Text(
                'Historical Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Lean Frequency',
                      '${(analysis.historicalAnalysis.monthly.leanFrequency * 100).toStringAsFixed(1)}%',
                      Icons.trending_down,
                      theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Avg Severity',
                      '₹${analysis.historicalAnalysis.monthly.avgLeanSeverity.toStringAsFixed(2)}',
                      Icons.attach_money,
                      theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cash Flow Forecast Summary
              Text(
                'Forecast Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildForecastRow(
                      context,
                      'Avg Monthly Income',
                      '₹${analysis.cashFlowForecast.avgMonthlyIncome.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _buildForecastRow(
                      context,
                      'Avg Monthly Expenses',
                      '₹${analysis.cashFlowForecast.avgMonthlyExpenses.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _buildForecastRow(
                      context,
                      'Income Volatility',
                      '${(analysis.cashFlowForecast.incomeVolatility * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warnings
              if (analysis.cashFlowForecast.warnings.isNotEmpty) ...[
                Text(
                  'Warnings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...analysis.cashFlowForecast.warnings.map((warning) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          warning,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastTab(BuildContext context, forecast) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Avg Income',
                      '₹${forecast.avgMonthlyIncome.toStringAsFixed(2)}',
                      Icons.arrow_upward,
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Avg Expenses',
                      '₹${forecast.avgMonthlyExpenses.toStringAsFixed(2)}',
                      Icons.arrow_downward,
                      theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                'Volatility',
                '${(forecast.incomeVolatility * 100).toStringAsFixed(1)}%',
                Icons.show_chart,
                theme.colorScheme.error,
              ),
              const SizedBox(height: 24),

              // Forecast Periods
              Text(
                'Monthly Forecasts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...forecast.forecasts.map((period) => _buildForecastPeriodCard(
                    context,
                    period,
                  )),
              const SizedBox(height: 16),

              // Warnings
              if (forecast.warnings.isNotEmpty) ...[
                Text(
                  'Warnings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...forecast.warnings.map((warning) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          warning,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab(BuildContext context, recommendations) {
    final theme = Theme.of(context);
    final strategy = recommendations.strategy;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Emergency Fund Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.savings,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Fund',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Target: ₹${recommendations.targetEmergencyFund.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: recommendations.currentBalance /
                          recommendations.targetEmergencyFund,
                      backgroundColor: theme.colorScheme.surface.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ₹${recommendations.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Gap: ₹${recommendations.emergencyFundGap.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Savings Recommendation
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Recommendation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendationRow(
                      context,
                      'Monthly Save Amount',
                      '₹${recommendations.monthlySaveAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _buildRecommendationRow(
                      context,
                      'Save Rate',
                      '${(recommendations.recommendedSaveRate * 100).toStringAsFixed(1)}%',
                    ),
                    if (recommendations.monthsToTarget != null) ...[
                      const Divider(height: 24),
                      _buildRecommendationRow(
                        context,
                        'Months to Target',
                        '${recommendations.monthsToTarget!.toStringAsFixed(1)} months',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Strategy
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getVolatilityColor(strategy.volatilityLevel, theme).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getVolatilityColor(strategy.volatilityLevel, theme).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Volatility: ${strategy.volatilityLevel.toUpperCase()}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (strategy.recommendations.isNotEmpty) ...[
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...strategy.recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    if (strategy.actionItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Action Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...strategy.actionItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastPeriodCard(BuildContext context, period) {
    final theme = Theme.of(context);
    final isLean = period.isLeanPeriod;
    final isRisk = period.balanceAtRisk;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRisk
            ? theme.colorScheme.error.withOpacity(0.1)
            : isLean
                ? theme.colorScheme.error.withOpacity(0.05)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRisk
              ? theme.colorScheme.error.withOpacity(0.3)
              : isLean
                  ? theme.colorScheme.error.withOpacity(0.2)
                  : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Month ${period.period}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isLean)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Lean Period',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (isRisk)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'At Risk',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildScenarioRow('Best', period.netCashFlow.best, theme.colorScheme.primary),
          _buildScenarioRow('Likely', period.netCashFlow.likely, theme.colorScheme.primary),
          _buildScenarioRow('Worst', period.netCashFlow.worst, theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildScenarioRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(
      BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel, ThemeData theme) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return theme.colorScheme.primary;
      case 'MODERATE':
        return theme.colorScheme.error;
      case 'HIGH':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Icons.check_circle;
      case 'MODERATE':
        return Icons.warning;
      case 'HIGH':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getVolatilityColor(String level, ThemeData theme) {
    switch (level.toLowerCase()) {
      case 'low':
        return theme.colorScheme.primary.withOpacity(0.2);
      case 'medium':
        return theme.colorScheme.error.withOpacity(0.2);
      case 'high':
        return theme.colorScheme.error.withOpacity(0.3);
      default:
        return theme.colorScheme.surface.withOpacity(0.5);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

