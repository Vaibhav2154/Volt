import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../init_dependencies.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_event.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/goals/presentation/bloc/goal_bloc.dart';
import '../../features/lean_week/presentation/pages/lean_week_page.dart';
import '../../features/lean_week/presentation/bloc/lean_week_bloc.dart';

/// Main navigation structure with bottom navigation bar
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      BlocProvider(
        create: (_) => sl<TransactionBloc>()..add(const LoadTransactionsEvent()),
        child: const DashboardPage(),
      ),
      BlocProvider(
        create: (_) => sl<TransactionBloc>()..add(const LoadTransactionsEvent()),
        child: const TransactionsPage(),
      ),
      BlocProvider(
        create: (_) => sl<GoalBloc>(),
        child: const GoalsPage(),
      ),
      BlocProvider(
        create: (_) => sl<LeanWeekBloc>(),
        child: const LeanWeekPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Plan',
          ),
        ],
      ),
    );
  }
}
