import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/simulation_bloc.dart';
import '../bloc/simulation_event.dart';
import '../bloc/simulation_state.dart';
import '../widgets/markdown_insight_widget.dart';

class SimulationsPage extends StatefulWidget {
  const SimulationsPage({super.key});

  @override
  State<SimulationsPage> createState() => _SimulationsPageState();
}

class _SimulationsPageState extends State<SimulationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _scenarioType = 'reduction';
  double _targetPercent = 10.0;
  int _timePeriodDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Tab change completed if needed
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
            return const Scaffold(
              body: LoadingState(message: 'Loading...'),
            );
          }

          final user = authState.user;

          return BlocConsumer<SimulationBloc, SimulationState>(
            listener: (context, state) {
              if (state is SimulationError) {
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
                          'What-If Simulations',
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
                            Tab(text: 'Simulate', icon: Icon(Icons.calculate)),
                            Tab(text: 'Compare', icon: Icon(Icons.compare_arrows)),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSimulateTab(context, user.id),
                    _buildCompareTab(context, user.id),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSimulateTab(BuildContext context, int userId) {
    return BlocBuilder<SimulationBloc, SimulationState>(
      builder: (context, state) {
        if (state is SimulationLoading) {
          return const Center(
            child: LoadingState(message: 'Running simulation...'),
          );
        }

        if (state is SimulationEnhancedLoaded) {
          return _buildSimulationResults(context, state.insight);
        }

        if (state is SimulationRefinedLoaded) {
          return _buildRefinedSimulationResults(context, state.response);
        }

        if (state is SimulationError) {
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
                  onPressed: () {
                    // Just rebuild to show form again
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        return _buildSimulateForm(context, userId);
      },
    );
  }

  Widget _buildSimulateForm(BuildContext context, int userId) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Spending Simulation',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See how reducing or increasing your spending would impact your finances',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scenario Type
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _scenarioType,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Scenario Type',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.trending_up,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        dropdownColor: theme.colorScheme.surface,
                        items: const [
                          DropdownMenuItem(value: 'reduction', child: Text('Reduction')),
                          DropdownMenuItem(value: 'increase', child: Text('Increase')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _scenarioType = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Target Percentage
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: TextFormField(
                        initialValue: _targetPercent.toString(),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Target Percentage (%)',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          hintText: 'Enter percentage (1-100)',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          helperText: 'How much to reduce or increase spending',
                          helperStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.percent,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a target percentage';
                          }
                          final percent = double.tryParse(value);
                          if (percent == null || percent <= 0 || percent > 100) {
                            return 'Please enter a valid percentage (1-100)';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          if (value != null) {
                            _targetPercent = double.tryParse(value) ?? 10.0;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Time Period
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: TextFormField(
                        initialValue: _timePeriodDays.toString(),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Analysis Period (days)',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          hintText: 'Enter number of days',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          helperText: 'Number of days to analyze',
                          helperStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a time period';
                          }
                          final days = int.tryParse(value);
                          if (days == null || days <= 0 || days > 365) {
                            return 'Please enter a valid number of days (1-365)';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          if (value != null) {
                            _timePeriodDays = int.tryParse(value) ?? 30;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  final authLocalDataSource = sl<AuthLocalDataSource>();
                                  final token = await authLocalDataSource.getToken();
                                  if (token != null) {
                                    context.read<SimulationBloc>().add(
                                          SimulateSpendingRefinedEvent(
                                            token: token,
                                            userId: userId,
                                            scenarioType: _scenarioType,
                                            targetPercent: _targetPercent,
                                            timePeriodDays: _timePeriodDays,
                                          ),
                                        );
                                  }
                                }
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text(
                                'Run with AI Insight',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  final authLocalDataSource = sl<AuthLocalDataSource>();
                                  final token = await authLocalDataSource.getToken();
                                  if (token != null) {
                                    context.read<SimulationBloc>().add(
                                          SimulateSpendingEnhancedEvent(
                                            token: token,
                                            userId: userId,
                                            scenarioType: _scenarioType,
                                            targetPercent: _targetPercent,
                                            timePeriodDays: _timePeriodDays,
                                          ),
                                        );
                                  }
                                }
                              },
                              icon: const Icon(Icons.calculate),
                              label: const Text(
                                'Enhanced',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationResults(BuildContext context, insight) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.headline,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      insight.confidenceReason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (insight.quickWins.isNotEmpty) ...[
                Text(
                  'Quick Wins',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.quickWins.map((win) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          win.difficulty == 'easy'
                              ? Icons.check_circle
                              : win.difficulty == 'moderate'
                                  ? Icons.info
                                  : Icons.warning,
                          color: win.difficulty == 'easy'
                              ? theme.colorScheme.primary
                              : win.difficulty == 'moderate'
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                        ),
                        title: Text(
                          win.category,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          win.action,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: Text(
                          '₹${win.monthlyImpact.toStringAsFixed(0)}/mo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              if (insight.warnings.isNotEmpty) ...[
                Text(
                  'Warnings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.warnings.map((warning) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: warning.severity == 'error'
                            ? theme.colorScheme.error.withOpacity(0.1)
                            : warning.severity == 'warning'
                                ? theme.colorScheme.error.withOpacity(0.05)
                                : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: warning.severity == 'error'
                              ? theme.colorScheme.error.withOpacity(0.3)
                              : warning.severity == 'warning'
                                  ? theme.colorScheme.error.withOpacity(0.2)
                                  : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          warning.severity == 'error'
                              ? Icons.error
                              : warning.severity == 'warning'
                                  ? Icons.warning
                                  : Icons.info,
                          color: warning.severity == 'error'
                              ? theme.colorScheme.error
                              : warning.severity == 'warning'
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                        ),
                        title: Text(
                          warning.message,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: warning.recommendation != null
                            ? Text(
                                warning.recommendation!,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              )
                            : null,
                      ),
                    )),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareTab(BuildContext context, int userId) {
    return BlocBuilder<SimulationBloc, SimulationState>(
      builder: (context, state) {
        if (state is SimulationLoading) {
          return const Center(
            child: LoadingState(message: 'Comparing scenarios...'),
          );
        }

        if (state is ScenariosCompared) {
          return _buildComparisonResults(context, state.comparison);
        }

        if (state is ComparisonRefinedLoaded) {
          return _buildRefinedComparisonResults(context, state.response);
        }

        if (state is SimulationError) {
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
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Compare Multiple Scenarios',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See how different spending reduction strategies compare side-by-side',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final authLocalDataSource = sl<AuthLocalDataSource>();
                              final token = await authLocalDataSource.getToken();
                              if (token != null) {
                                context.read<SimulationBloc>().add(
                                      CompareScenariosRefinedEvent(
                                        token: token,
                                        userId: userId,
                                        scenarioType: 'reduction',
                                      ),
                                    );
                              }
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text(
                              'With AI Insight',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final authLocalDataSource = sl<AuthLocalDataSource>();
                              final token = await authLocalDataSource.getToken();
                              if (token != null) {
                                context.read<SimulationBloc>().add(
                                      CompareScenariosEvent(
                                        token: token,
                                        userId: userId,
                                        scenarioType: 'reduction',
                                      ),
                                    );
                              }
                            },
                            icon: const Icon(Icons.compare_arrows),
                            label: const Text(
                              'Standard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefinedSimulationResults(BuildContext context, refinedResponse) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // AI Insight Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insight',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MarkdownInsightWidget(
                        markdown: refinedResponse.refinedInsight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Simulation Details
              Text(
                'Simulation Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildSimulationSummaryCard(theme, refinedResponse.simulation),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRefinedComparisonResults(BuildContext context, refinedResponse) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // AI Insight Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insight',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MarkdownInsightWidget(
                        markdown: refinedResponse.refinedInsight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Comparison Details
              Text(
                'Scenario Comparison',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...refinedResponse.comparison.scenarios.map((scenario) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        scenario.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        scenario.description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildComparisonRow('Target', '${scenario.targetPercent}%', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Achievable', '${scenario.achievablePercent.toStringAsFixed(1)}%', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Monthly Impact', '₹${scenario.totalChange.toStringAsFixed(2)}', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Annual Impact', '₹${scenario.annualImpact.toStringAsFixed(2)}', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Feasibility', scenario.feasibility.replaceAll('_', ' ').toUpperCase(), theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Key Insight', scenario.keyInsight, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationSummaryCard(ThemeData theme, simulation) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baseline Monthly',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '₹${simulation.baselineMonthly.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected Monthly',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '₹${simulation.projectedMonthly.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: simulation.totalChange >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Change',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '₹${simulation.totalChange.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: simulation.totalChange >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Annual Impact',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '₹${simulation.annualImpact.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Feasibility',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getFeasibilityColor(simulation.feasibility, theme).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getFeasibilityColor(simulation.feasibility, theme).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  simulation.feasibility.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: _getFeasibilityColor(simulation.feasibility, theme),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFeasibilityColor(String feasibility, ThemeData theme) {
    switch (feasibility.toLowerCase()) {
      case 'highly_achievable':
        return theme.colorScheme.primary;
      case 'achievable':
        return theme.colorScheme.primary;
      case 'challenging':
        return theme.colorScheme.error;
      case 'unrealistic':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildComparisonResults(BuildContext context, comparison) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Scenario Comparison',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...comparison.scenarios.map((scenario) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        scenario.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        scenario.description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildComparisonRow('Target', '${scenario.targetPercent}%', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Achievable', '${scenario.achievablePercent.toStringAsFixed(1)}%', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Monthly Impact', '₹${scenario.totalChange.toStringAsFixed(2)}', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Annual Impact', '₹${scenario.annualImpact.toStringAsFixed(2)}', theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Feasibility', scenario.feasibility.replaceAll('_', ' ').toUpperCase(), theme),
                              const SizedBox(height: 8),
                              _buildComparisonRow('Key Insight', scenario.keyInsight, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ]),
          ),
        ),
      ],
    );
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

