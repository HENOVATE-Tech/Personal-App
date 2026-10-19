import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/notification_service.dart';
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
      backgroundColor: Colors.transparent,
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

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 600;
    final bottomInset = mediaQuery.padding.bottom;

    final shellContent = Stack(
      children: [
        // Active Screen Content
        IndexedStack(
          index: _currentIndex,
          children: screens,
        ),

        // Floating Top Ringing Alarm Banner
        StreamBuilder<ScheduledAlarm?>(
          stream: NotificationService.instance.ringingAlarmStream,
          initialData: NotificationService.instance.currentRingingAlarm,
          builder: (context, snapshot) {
            final alarm = snapshot.data;
            if (alarm == null) return const SizedBox.shrink();

            final topPadding = MediaQuery.of(context).padding.top;
            return Positioned(
              top: topPadding > 0 ? topPadding + 8 : 16,
              left: 14,
              right: 14,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(24),
                shadowColor: const Color(0xFFDC2626).withOpacity(0.5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'ALARM RINGING ⏰',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              alarm.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => NotificationService.instance.snoozeActiveAlarm(minutes: 5),
                        child: const Text('Snooze', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => NotificationService.instance.dismissActiveAlarm(),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Modern Floating Bottom Navigation Bar (matching reference UI)
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset > 0 ? bottomInset + 8 : 16,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Today'),
                _buildNavItem(1, Icons.calendar_month, Icons.calendar_month_outlined, 'Plan'),
                _buildNavItem(2, Icons.check_circle, Icons.check_circle_outline, 'Tasks'),
                _buildNavItem(3, Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 'Finance'),
                _buildNavItem(4, Icons.widgets, Icons.widgets_outlined, 'More'),
              ],
            ),
          ),
        ),
      ],
    );

    if (!isDesktop) {
      // Mobile View: Full 100% width, native mobile experience with no side letterboxing
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SizedBox.expand(
          child: shellContent,
        ),
      );
    }

    // Desktop/Wide View: Centered mobile mockup frame with soft backdrop
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppTheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: shellContent,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECE5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.coralPrimary : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.coralPrimary : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
