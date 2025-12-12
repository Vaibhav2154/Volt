import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../init_dependencies.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/simulation_bloc.dart';
import '../bloc/simulation_event.dart';
import '../bloc/simulation_state.dart';

class SimulationsPage extends StatefulWidget {
  const SimulationsPage({super.key});

  @override
  State<SimulationsPage> createState() => _SimulationsPageState();
}

class _SimulationsPageState extends State<SimulationsPage>
    with SingleTickerProviderStateMixin {
  String? _token;
  int? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final token = await authLocalDataSource.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    setState(() {
      _token = token;
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_token == null || _userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('What-If Simulations'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'What-If Simulations',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSimulateTab(context),
          _buildCompareTab(context),
        ],
      ),
    );
  }

  Widget _buildSimulateTab(BuildContext context) {
    return BlocBuilder<SimulationBloc, SimulationState>(
      builder: (context, state) {
        if (state is SimulationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SimulationEnhancedLoaded) {
          return _buildSimulationResults(context, state.insight);
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return _buildSimulateForm(context);
      },
    );
  }

  Widget _buildSimulateForm(BuildContext context) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    String scenarioType = 'reduction';
    double targetPercent = 10.0;
    int timePeriodDays = 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Spending Simulation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See how reducing or increasing your spending would impact your finances',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              value: scenarioType,
              decoration: const InputDecoration(
                labelText: 'Scenario Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'reduction', child: Text('Reduction')),
                DropdownMenuItem(value: 'increase', child: Text('Increase')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    scenarioType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: targetPercent.toString(),
              decoration: const InputDecoration(
                labelText: 'Target Percentage (%)',
                border: OutlineInputBorder(),
                helperText: 'How much to reduce or increase spending',
              ),
              keyboardType: TextInputType.number,
              onSaved: (value) {
                if (value != null) {
                  targetPercent = double.tryParse(value) ?? 10.0;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: timePeriodDays.toString(),
              decoration: const InputDecoration(
                labelText: 'Analysis Period (days)',
                border: OutlineInputBorder(),
                helperText: 'Number of days to analyze',
              ),
              keyboardType: TextInputType.number,
              onSaved: (value) {
                if (value != null) {
                  timePeriodDays = int.tryParse(value) ?? 30;
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    context.read<SimulationBloc>().add(
                          SimulateSpendingEnhancedEvent(
                            token: _token!,
                            userId: _userId!,
                            scenarioType: scenarioType,
                            targetPercent: targetPercent,
                            timePeriodDays: timePeriodDays,
                          ),
                        );
                  }
                },
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'Run Simulation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationResults(BuildContext context, insight) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.headline,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.confidenceReason,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (insight.quickWins.isNotEmpty) ...[
            Text(
              'Quick Wins',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...insight.quickWins.map((win) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      win.difficulty == 'easy'
                          ? Icons.check_circle
                          : win.difficulty == 'moderate'
                              ? Icons.info
                              : Icons.warning,
                      color: win.difficulty == 'easy'
                          ? Colors.green
                          : win.difficulty == 'moderate'
                              ? Colors.orange
                              : Colors.red,
                    ),
                    title: Text(win.category),
                    subtitle: Text(win.action),
                    trailing: Text(
                      '₹${win.monthlyImpact.toStringAsFixed(0)}/mo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
              ),
            ),
            const SizedBox(height: 8),
            ...insight.warnings.map((warning) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: warning.severity == 'error'
                      ? Colors.red.shade50
                      : warning.severity == 'warning'
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                  child: ListTile(
                    leading: Icon(
                      warning.severity == 'error'
                          ? Icons.error
                          : warning.severity == 'warning'
                              ? Icons.warning
                              : Icons.info,
                      color: warning.severity == 'error'
                          ? Colors.red
                          : warning.severity == 'warning'
                              ? Colors.orange
                              : Colors.blue,
                    ),
                    title: Text(warning.message),
                    subtitle: warning.recommendation != null
                        ? Text(warning.recommendation!)
                        : null,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCompareTab(BuildContext context) {
    return BlocBuilder<SimulationBloc, SimulationState>(
      builder: (context, state) {
        if (state is SimulationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ScenariosCompared) {
          return _buildComparisonResults(context, state.comparison);
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Center(
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<SimulationBloc>().add(
                    CompareScenariosEvent(
                      token: _token!,
                      userId: _userId!,
                      scenarioType: 'reduction',
                    ),
                  );
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare Scenarios'),
          ),
        );
      },
    );
  }

  Widget _buildComparisonResults(BuildContext context, comparison) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario Comparison',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...comparison.scenarios.map((scenario) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(scenario.name),
                  subtitle: Text(scenario.description),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target: ${scenario.targetPercent}%'),
                          Text('Achievable: ${scenario.achievablePercent.toStringAsFixed(1)}%'),
                          Text('Monthly Impact: ₹${scenario.totalChange.toStringAsFixed(2)}'),
                          Text('Annual Impact: ₹${scenario.annualImpact.toStringAsFixed(2)}'),
                          Text('Feasibility: ${scenario.feasibility}'),
                          Text('Key Insight: ${scenario.keyInsight}'),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

}

