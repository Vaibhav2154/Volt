import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/health_score_bloc.dart';
import '../bloc/health_score_event.dart';
import '../bloc/health_score_state.dart';

class HealthScorePage extends StatefulWidget {
  const HealthScorePage({super.key});

  @override
  State<HealthScorePage> createState() => _HealthScorePageState();
}

class _HealthScorePageState extends State<HealthScorePage> {
  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();
    final authLocalDataSource = AuthLocalDataSourceImpl(
      secureStorage: secureStorage,
      sharedPreferences: prefs,
    );
    final token = await authLocalDataSource.getToken();
    final userId = prefs.getInt('user_id');
    
    if (token != null && userId != null) {
      setState(() {
        _token = token;
        _userId = userId;
      });
      
      if (mounted) {
        context.read<HealthScoreBloc>().add(
              LoadHealthScoreEvent(
                token: token,
                userId: userId,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Financial Health Score',
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
                  if (_token != null && _userId != null) {
                    context.read<HealthScoreBloc>().add(
                          RefreshHealthScoreEvent(
                            token: _token!,
                            userId: _userId!,
                          ),
                        );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<HealthScoreBloc, HealthScoreState>(
              builder: (context, state) {
                if (state is HealthScoreLoading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is HealthScoreError) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.message,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_token != null && _userId != null) {
                                context.read<HealthScoreBloc>().add(
                                      LoadHealthScoreEvent(
                                        token: _token!,
                                        userId: _userId!,
                                      ),
                                    );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is HealthScoreLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_token != null && _userId != null) {
                        context.read<HealthScoreBloc>().add(
                              RefreshHealthScoreEvent(
                                token: _token!,
                                userId: _userId!,
                              ),
                            );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScoreCard(context, state.score),
                          const SizedBox(height: 16),
                          _buildBreakdownCard(context, state.score),
                          const SizedBox(height: 16),
                          if (state.score.trend.isNotEmpty) ...[
                            _buildTrendCard(context, state.score),
                            const SizedBox(height: 16),
                          ],
                          if (state.score.recommendations.isNotEmpty) ...[
                            _buildRecommendationsCard(context, state.score),
                            const SizedBox(height: 16),
                          ],
                          _buildFactorsCard(context, state.score),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox(
                  height: 400,
                  child: Center(child: Text('No data available')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, score) {
    final theme = Theme.of(context);
    final scoreValue = score.overallScore;
    final grade = score.grade;
    
    // Determine color based on score using theme colors
    Color scoreColor;
    if (scoreValue >= 80) {
      scoreColor = theme.colorScheme.primary;
    } else if (scoreValue >= 60) {
      scoreColor = ColorPalette.warning;
    } else {
      scoreColor = theme.colorScheme.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Your Financial Health Score',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: scoreValue / 100,
                    strokeWidth: 20,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      scoreValue.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              score.scoreDescription,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDataQualityColor(score.dataQuality, theme).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Data Quality: ${score.dataQuality.toUpperCase()}',
                style: TextStyle(
                  color: _getDataQualityColor(score.dataQuality, theme),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(BuildContext context, score) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(context, 'Income Stability', score.breakdown.incomeStability),
            _buildBreakdownItem(context, 'Spending Discipline', score.breakdown.spendingDiscipline),
            _buildBreakdownItem(context, 'Emergency Fund', score.breakdown.emergencyFund),
            _buildBreakdownItem(context, 'Savings Rate', score.breakdown.savingsRate),
            _buildBreakdownItem(context, 'Debt Health', score.breakdown.debtHealth),
            _buildBreakdownItem(context, 'Diversification', score.breakdown.diversification),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final color = value >= 70
        ? theme.colorScheme.primary
        : value >= 50
            ? ColorPalette.warning
            : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, score) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Trend (Last 6 Months)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: score.trend.length,
                itemBuilder: (context, index) {
                  final trend = score.trend[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (trend.score / 100) * 150,
                          width: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trend.score.toStringAsFixed(0),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${trend.date.month}/${trend.date.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, score) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...score.recommendations.map((rec) => _buildRecommendationItem(context, rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, rec) {
    final theme = Theme.of(context);
    final priorityColor = rec.priority == 'high'
        ? theme.colorScheme.error
        : rec.priority == 'medium'
            ? ColorPalette.warning
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.lightbulb_outline,
          color: priorityColor,
        ),
        title: Text(
          rec.action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.impact),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rec.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${rec.estimatedScoreGain.toStringAsFixed(0)} pts',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsCard(BuildContext context, score) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Factors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (score.factors.positiveFactors.isNotEmpty) ...[
              Text(
                'Positive Factors',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...score.factors.positiveFactors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(factor)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (score.factors.negativeFactors.isNotEmpty) ...[
              Text(
                'Areas for Improvement',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorPalette.warning,
                ),
              ),
              const SizedBox(height: 8),
              ...score.factors.negativeFactors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: ColorPalette.warning, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(factor)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (score.factors.criticalIssues.isNotEmpty) ...[
              Text(
                'Critical Issues',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              ...score.factors.criticalIssues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: theme.colorScheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDataQualityColor(String quality, ThemeData theme) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return theme.colorScheme.primary;
      case 'good':
        return theme.colorScheme.primary;
      case 'fair':
        return ColorPalette.warning;
      case 'poor':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }
}

