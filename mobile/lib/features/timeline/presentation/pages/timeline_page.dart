import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../bloc/timeline_bloc.dart';
import '../bloc/timeline_event.dart';
import '../bloc/timeline_state.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  String? _token;
  int? _userId;
  String _timelineType = 'monthly';
  int _periods = 12;
  bool _includeForecast = true;

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
        context.read<TimelineBloc>().add(
              LoadTimelineEvent(
                token: token,
                userId: userId,
                timelineType: _timelineType,
                periods: _periods,
                includeForecast: _includeForecast,
              ),
            );
      }
    }
  }

  void _loadTimeline() {
    if (_token != null && _userId != null) {
      context.read<TimelineBloc>().add(
            LoadTimelineEvent(
              token: _token!,
              userId: _userId!,
              timelineType: _timelineType,
              periods: _periods,
              includeForecast: _includeForecast,
            ),
          );
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
                'Cash Flow Timeline',
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _timelineType = value;
                  });
                  _loadTimeline();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'monthly', child: Text('Monthly')),
                  const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _timelineType.toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _loadTimeline,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<TimelineBloc, TimelineState>(
              builder: (context, state) {
                if (state is TimelineLoading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TimelineError) {
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
                            onPressed: _loadTimeline,
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

                if (state is TimelineLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadTimeline();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatisticsCard(context, state.timeline),
                          const SizedBox(height: 16),
                          _buildTimelineVisualization(context, state.timeline),
                          const SizedBox(height: 16),
                          if (state.timeline.forecastPeriods.isNotEmpty) ...[
                            _buildForecastCard(context, state.timeline),
                            const SizedBox(height: 16),
                          ],
                          if (state.timeline.welfordStats != null) ...[
                            _buildWelfordCard(context, state.timeline.welfordStats!),
                          ],
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

  Widget _buildStatisticsCard(BuildContext context, timeline) {
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
              'Summary Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Income',
                    '₹${timeline.statistics.totalIncome.toStringAsFixed(0)}',
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Expenses',
                    '₹${timeline.statistics.totalExpenses.toStringAsFixed(0)}',
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Net Flow',
                    '₹${timeline.statistics.totalNetFlow.toStringAsFixed(0)}',
                    timeline.statistics.totalNetFlow >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Net Flow',
                    '₹${timeline.statistics.avgNetFlow.toStringAsFixed(0)}',
                    ColorPalette.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Lean Periods',
                    '${timeline.statistics.leanPeriodCount}',
                    ColorPalette.warning,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Lean Frequency',
                    '${(timeline.statistics.leanFrequency * 100).toStringAsFixed(1)}%',
                    ColorPalette.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineVisualization(BuildContext context, timeline) {
    final theme = Theme.of(context);
    final periods = timeline.historicalPeriods;
    
    if (periods.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
      );
    }
    
    // Calculate max income for scaling
    final maxIncome = periods.map((p) => p.income).reduce((a, b) => a > b ? a : b);
    final minIncome = periods.map((p) => p.income).reduce((a, b) => a < b ? a : b);
    final incomeRange = maxIncome - minIncome;
    final graphHeight = 300.0;
    
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
              'Income Timeline',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: graphHeight + 80,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate minimum width needed for all nodes
                  final minNodeSpacing = 120.0; // Minimum spacing between nodes
                  final minWidth = periods.length > 1 
                      ? (periods.length - 1) * minNodeSpacing + 120 // padding on both sides
                      : 200.0;
                  final graphWidth = minWidth > constraints.maxWidth 
                      ? minWidth 
                      : constraints.maxWidth;
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: graphWidth,
                      child: CustomPaint(
                        size: Size(graphWidth, graphHeight + 80),
                        painter: _TimelineGraphPainter(
                          periods: periods,
                          maxIncome: maxIncome,
                          minIncome: minIncome,
                          incomeRange: incomeRange,
                          graphHeight: graphHeight,
                          theme: theme,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(theme, theme.colorScheme.primary, 'Income'),
                const SizedBox(width: 16),
                _buildLegendItem(theme, theme.colorScheme.error, 'Lean Period'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(BuildContext context, timeline) {
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
              'Forecast',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...timeline.forecastPeriods.map((forecast) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: forecast.isPredictedLean
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    title: Text(_formatPeriodKey(forecast.periodKey)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildForecastItem(
                                'Best',
                                forecast.bestCase,
                                theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: _buildForecastItem(
                                'Likely',
                                forecast.likelyCase,
                                ColorPalette.info,
                              ),
                            ),
                            Expanded(
                              child: _buildForecastItem(
                                'Worst',
                                forecast.worstCase,
                                theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Confidence: ${(forecast.confidence * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: forecast.isPredictedLean
                        ? Icon(Icons.warning, color: theme.colorScheme.error)
                        : null,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelfordCard(BuildContext context, welfordStats) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
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
            Row(
              children: [
                Icon(Icons.calculate, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  welfordStats.algorithmName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWelfordStat('Sample Count', welfordStats.sampleCount.toString(), theme),
            _buildWelfordStat('Running Mean', welfordStats.runningMean.toStringAsFixed(2), theme),
            _buildWelfordStat('Running Variance', welfordStats.runningVariance.toStringAsFixed(2), theme),
            _buildWelfordStat('Std Deviation', welfordStats.runningStdDev.toStringAsFixed(2), theme),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    welfordStats.isNumericallyStable
                        ? Icons.check_circle
                        : Icons.error,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Numerically Stable: ${welfordStats.isNumericallyStable ? "Yes" : "No"}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelfordStat(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeriodKey(String periodKey) {
    // Format period key for display (e.g., "2025-01" -> "Jan 2025" or "2025-W01" -> "Week 1")
    if (periodKey.contains('W')) {
      // Weekly format
      final parts = periodKey.split('-W');
      return 'W${parts[1]}';
    } else {
      // Monthly format
      try {
        final date = DateTime.parse('$periodKey-01');
        return DateFormat('MMM yyyy').format(date);
      } catch (e) {
        return periodKey;
      }
    }
  }
}

class _TimelineGraphPainter extends CustomPainter {
  final List periods;
  final double maxIncome;
  final double minIncome;
  final double incomeRange;
  final double graphHeight;
  final ThemeData theme;

  _TimelineGraphPainter({
    required this.periods,
    required this.maxIncome,
    required this.minIncome,
    required this.incomeRange,
    required this.graphHeight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (periods.isEmpty) return;

    final nodeRadius = 10.0;
    // Calculate dynamic spacing based on available width and number of periods
    final horizontalPadding = 60.0; // Increased padding to prevent edge cutoff
    final availableWidth = size.width - (horizontalPadding * 2);
    final nodeSpacing = periods.length > 1 
        ? availableWidth / (periods.length - 1)
        : 0.0;
    
    final verticalPadding = 50.0; // Top padding for income labels
    final bottomPadding = 40.0; // Bottom padding for period labels
    final availableHeight = graphHeight - verticalPadding - bottomPadding;

    // Draw connecting lines first (behind nodes)
    final linePaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < periods.length - 1; i++) {
      final period1 = periods[i];
      final period2 = periods[i + 1];
      
      final x1 = horizontalPadding + (i * nodeSpacing);
      final normalizedY1 = incomeRange > 0 
          ? ((period1.income - minIncome) / incomeRange)
          : 0.5;
      final y1 = verticalPadding + availableHeight - (normalizedY1 * availableHeight);
      
      final x2 = horizontalPadding + ((i + 1) * nodeSpacing);
      final normalizedY2 = incomeRange > 0 
          ? ((period2.income - minIncome) / incomeRange)
          : 0.5;
      final y2 = verticalPadding + availableHeight - (normalizedY2 * availableHeight);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Draw nodes and labels
    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      final x = horizontalPadding + (i * nodeSpacing);
      final normalizedY = incomeRange > 0 
          ? ((period.income - minIncome) / incomeRange)
          : 0.5;
      final y = verticalPadding + availableHeight - (normalizedY * availableHeight);

      // Ensure node is within bounds
      if (x < nodeRadius || x > size.width - nodeRadius) continue;

      // Node color based on lean period
      final nodeColor = period.isLean 
          ? theme.colorScheme.error 
          : theme.colorScheme.primary;

      // Draw connecting line shadow effect (optional)
      if (i > 0) {
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        final prevPeriod = periods[i - 1];
        final prevNormalizedY = incomeRange > 0 
            ? ((prevPeriod.income - minIncome) / incomeRange)
            : 0.5;
        final prevY = verticalPadding + availableHeight - (prevNormalizedY * availableHeight);
        final prevX = horizontalPadding + ((i - 1) * nodeSpacing);
        canvas.drawLine(Offset(prevX, prevY), Offset(x, y), shadowPaint);
      }

      // Draw node with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x + 1, y + 1), nodeRadius, shadowPaint);

      // Draw node
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), nodeRadius, nodePaint);

      // Draw node border
      final borderPaint = Paint()
        ..color = theme.colorScheme.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      
      canvas.drawCircle(Offset(x, y), nodeRadius, borderPaint);

      // Draw income value above node with background
      final incomeText = '₹${period.income.toStringAsFixed(0)}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: incomeText,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      // Draw background for text
      final textBackgroundPaint = Paint()
        ..color = theme.colorScheme.surface.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      final textPadding = 4.0;
      final textRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - textPainter.width / 2 - textPadding,
          y - nodeRadius - 25 - textPainter.height - textPadding,
          textPainter.width + (textPadding * 2),
          textPainter.height + (textPadding * 2),
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(textRect, textBackgroundPaint);
      
      // Draw text border
      final textBorderPaint = Paint()
        ..color = nodeColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(textRect, textBorderPaint);
      
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - nodeRadius - 25 - textPainter.height),
      );

      // Draw period label below graph
      final periodLabel = _formatPeriodKeyForPainter(period.periodKey);
      final periodPainter = TextPainter(
        text: TextSpan(
          text: periodLabel,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      periodPainter.layout();
      periodPainter.paint(
        canvas,
        Offset(x - periodPainter.width / 2, graphHeight - bottomPadding + 15),
      );

      // Draw lean period indicator (outer ring)
      if (period.isLean) {
        final warningPaint = Paint()
          ..color = theme.colorScheme.error.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        canvas.drawCircle(Offset(x, y), nodeRadius + 4, warningPaint);
      }
    }
  }

  String _formatPeriodKeyForPainter(String periodKey) {
    if (periodKey.contains('W')) {
      final parts = periodKey.split('-W');
      return 'W${parts[1]}';
    } else {
      try {
        final date = DateTime.parse('$periodKey-01');
        return DateFormat('MMM').format(date);
      } catch (e) {
        return periodKey;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

