import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/activity_feed_item.dart';
import '../widgets/badge_card.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/streak_card.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<GamificationBloc>().add(LoadGamificationProfileEvent());
    context.read<GamificationBloc>().add(LoadGamificationFeedEvent());
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
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state is GamificationLoading && state is! GamificationProfileLoaded) {
            return const LoadingState(message: 'Loading your progress...');
          }

          if (state is GamificationError) {
            return ErrorState(
              message: state.message,
              onRetry: () {
                context.read<GamificationBloc>().add(LoadGamificationProfileEvent());
                context.read<GamificationBloc>().add(LoadGamificationFeedEvent());
              },
            );
          }

          return NestedScrollView(
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
                      'Achievements',
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
                        context
                            .read<GamificationBloc>()
                            .add(RefreshGamificationProfileEvent());
                        context
                            .read<GamificationBloc>()
                            .add(LoadGamificationFeedEvent());
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ];
            },
            body: Column(
              children: [
                Container(
                  color: theme.scaffoldBackgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: ColorPalette.green400,
                    labelColor: ColorPalette.green400,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Badges'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(context, state),
                      _buildBadgesTab(context, state),
                      _buildActivityTab(context, state),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, GamificationState state) {
    final theme = Theme.of(context);

    if (state is! GamificationProfileLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GamificationBloc>().add(RefreshGamificationProfileEvent());
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LevelProgressCard(
              level: profile.level,
              xpTotal: profile.xpTotal,
              xpToNextLevel: profile.xpToNextLevel,
              nextLevelXp: profile.nextLevelXp,
            ),
          ),
          if (profile.streaks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Active Streaks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return StreakCard(streak: profile.streaks[index]);
                  },
                  childCount: profile.streaks.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildBadgesTab(BuildContext context, GamificationState state) {
    final theme = Theme.of(context);

    if (state is! GamificationProfileLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final badges = state.profile.badges;
    final earnedBadges = badges.where((b) => b.isEarned).toList();
    final lockedBadges = badges.where((b) => !b.isEarned).toList();

    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No badges yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete actions to unlock badges',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GamificationBloc>().add(RefreshGamificationProfileEvent());
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (earnedBadges.isNotEmpty) ...[
                    Text(
                      'Earned (${earnedBadges.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: earnedBadges.length,
                      itemBuilder: (context, index) {
                        return BadgeCard(badge: earnedBadges[index]);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (lockedBadges.isNotEmpty) ...[
                    Text(
                      'Locked (${lockedBadges.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: lockedBadges.length,
                      itemBuilder: (context, index) {
                        return BadgeCard(badge: lockedBadges[index]);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, GamificationState state) {
    final theme = Theme.of(context);

    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, feedState) {
        if (feedState is GamificationLoading && feedState is! GamificationFeedLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feedState is GamificationFeedLoaded) {
          final feed = feedState.feed;

          if (feed.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your achievements will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GamificationBloc>().add(LoadGamificationFeedEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feed.events.length,
              itemBuilder: (context, index) {
                return ActivityFeedItem(event: feed.events[index]);
              },
            ),
          );
        }

        // If no feed loaded yet, show loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

