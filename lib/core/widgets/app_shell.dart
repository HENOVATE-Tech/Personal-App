import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../../features/today/screens/today_dashboard_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/quick_capture_sheet.dart';
import '../../features/finance/screens/finance_overview_screen.dart';
import '../../features/finance/screens/transaction_editor_screen.dart';
import '../../features/more/screens/more_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _openQuickExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionEditorScreen(),
      ),
    );
  }

  void _openQuickTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickCaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TodayDashboardScreen(
        onQuickExpense: _openQuickExpense,
        onQuickTask: _openQuickTask,
      ),
      const CalendarScreen(),
      const TaskListScreen(),
      FinanceOverviewScreen(
        onAddTransaction: _openQuickExpense,
      ),
      const MoreHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppTheme.sereneTeal.withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: AppTheme.sereneTeal),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppTheme.sereneTeal),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: AppTheme.sereneTeal),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.sereneTeal),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: AppTheme.sereneTeal),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
