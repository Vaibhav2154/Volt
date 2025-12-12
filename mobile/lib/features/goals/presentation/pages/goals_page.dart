import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'create_edit_goal_page.dart';
import 'goal_detail_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  String? _token;
  bool _showActiveOnly = false;

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
      _loadGoals();
    }
  }

  void _loadGoals() {
    if (_token == null) return;
    context.read<GoalBloc>().add(
          LoadGoalsWithProgressEvent(
            token: _token!,
            activeOnly: _showActiveOnly,
          ),
        );
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
          'Goals',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
              _loadGoals();
            },
            tooltip: _showActiveOnly ? 'Show all goals' : 'Show active only',
          ),
        ],
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal created successfully'),
                backgroundColor: ColorPalette.success,
              ),
            );
            _loadGoals();
          } else if (state is GoalUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal updated successfully'),
                backgroundColor: ColorPalette.success,
              ),
            );
            _loadGoals();
          } else if (state is GoalDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goal deleted successfully'),
                backgroundColor: ColorPalette.success,
              ),
            );
            _loadGoals();
          } else if (state is GoalActivated || state is GoalDeactivated) {
            _loadGoals();
          } else if (state is GoalError) {
            // Only show error if it's not a loading state transition
            if (state.message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is GoalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GoalsWithProgressLoaded) {
            if (state.goals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first goal to start tracking',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCreateGoal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Goal'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadGoals(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.goals.length,
                itemBuilder: (context, index) {
                  final goal = state.goals[index];
                  return _buildGoalCard(context, goal);
                },
              ),
            );
          }

          if (state is GoalError) {
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
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGoals,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: _loadGoals,
              child: const Text('Load Goals'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () => _navigateToCreateGoal(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, goal) {
    final theme = Theme.of(context);
    final progress = goal.progressPercentage / 100;
    final isOverdue = goal.isOverdue;
    final isAchieved = goal.isAchieved;

    Color cardColor = theme.colorScheme.surface;
    if (isAchieved) {
      cardColor = ColorPalette.successLight;
    } else if (isOverdue) {
      cardColor = ColorPalette.errorLight;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: InkWell(
        onTap: () => _navigateToGoalDetail(context, goal.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isAchieved)
                    Chip(
                      label: const Text('Achieved'),
                      backgroundColor: ColorPalette.success,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  else if (isOverdue)
                    Chip(
                      label: const Text('Overdue'),
                      backgroundColor: ColorPalette.error,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  else if (!goal.isActive)
                    Chip(
                      label: const Text('Inactive'),
                      backgroundColor: Colors.grey,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${goal.currentAmount.toStringAsFixed(2)} / ₹${goal.targetAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.daysRemaining} days left',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAchieved
                        ? ColorPalette.success
                        : isOverdue
                            ? ColorPalette.error
                            : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.totalContributions} contributions',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (!goal.isActive && !isAchieved)
                    TextButton.icon(
                      onPressed: () => _activateGoal(context, goal.id),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Activate'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GoalBloc>(),
          child: const CreateEditGoalPage(),
        ),
      ),
    );
  }

  void _navigateToGoalDetail(BuildContext context, int goalId) {
    if (_token == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GoalBloc>()
            ..add(LoadGoalEvent(token: _token!, goalId: goalId)),
          child: GoalDetailPage(goalId: goalId),
        ),
      ),
    );
  }

  void _activateGoal(BuildContext context, int goalId) {
    if (_token == null) return;
    context.read<GoalBloc>().add(
          ActivateGoalEvent(token: _token!, goalId: goalId),
        );
  }
}

