import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/recurrence_engine.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';
import '../../../core/widgets/recovery_card_widget.dart';
import '../../../core/widgets/workspace_selector.dart';
import '../../recovery/services/commitment_recovery_engine.dart';

class TodayDashboardScreen extends StatefulWidget {
  final VoidCallback onQuickExpense;
  final VoidCallback onQuickTask;

  const TodayDashboardScreen({
    super.key,
    required this.onQuickExpense,
    required this.onQuickTask,
  });

  @override
  State<TodayDashboardScreen> createState() => _TodayDashboardScreenState();
}

class _TodayDashboardScreenState extends State<TodayDashboardScreen> {
  String _selectedWorkspaceId = '';
  bool _lowEnergyMode = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final profile = db.userProfile;
        final now = DateTime.now();

        // 1. Filter Tasks
        final allTasks = db.getTasks(workspaceId: _selectedWorkspaceId);
        final topPriorities = allTasks.where((t) => t.isTopPriority).take(3).toList();

        // 2. Active Routines
        final routines = db.getRoutineTemplates();

        // 3. Recovery Cards (max 3)
        final recoveryCards = CommitmentRecoveryEngine.instance.evaluateCommitments(referenceDate: now);

        // 4. Fasting Status
        final bool isMonday = now.weekday == DateTime.monday;
        final bool isFriday = now.weekday == DateTime.friday;
        final bool isLastWeekend = RecurrenceEngine.isLastFridayOfMonth(now) ||
            now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;
        final bool isFastingDay = isMonday || isFriday || isLastWeekend;

        // 5. Total Balances in Kobo
        final accounts = db.getFinancialAccounts();
        final totalBalanceKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatFullDate(now),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Peace, ${profile.displayName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      profile.privacyModeEnabled ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.sereneTeal,
                    ),
                    tooltip: 'Toggle Privacy Blur',
                    onPressed: () {
                      db.updateUserProfile(
                        profile.copyWith(privacyModeEnabled: !profile.privacyModeEnabled),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _lowEnergyMode ? Icons.battery_charging_full : Icons.battery_saver,
                      color: _lowEnergyMode ? AppTheme.softAmber : AppTheme.mutedGray,
                    ),
                    tooltip: 'Low-Energy Mode',
                    onPressed: () {
                      setState(() {
                        _lowEnergyMode = !_lowEnergyMode;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _lowEnergyMode
                                ? 'Low-Energy Mode active: Focus only on essentials today.'
                                : 'Standard Mode restored.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Workspace Filter Bar
              SliverToBoxAdapter(
                child: WorkspaceSelector(
                  selectedWorkspaceId: _selectedWorkspaceId,
                  onWorkspaceChanged: (id) => setState(() => _selectedWorkspaceId = id),
                ),
              ),

              // Fasting Banner if applicable
              if (isFastingDay)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop_outlined, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isLastWeekend
                                ? 'Monthly 3-Day Fast (Deduplicated): Stay gently hydrated throughout the weekend.'
                                : 'Scheduled Fast Day: Maintain hydration and take rest when needed.',
                            style: const TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Financial Quick Glance Card
              SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Liquid Funds',
                              style: TextStyle(color: AppTheme.mutedGray, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            PrivacyBlurWrapper(
                              child: Text(
                                MoneyFormatter.formatKobo(totalBalanceKobo),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.slateNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Quick Expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sereneTeal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: widget.onQuickExpense,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Commitment Recovery Queue (Max 3)
              if (recoveryCards.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      'Commitment Recovery (${recoveryCards.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softAmber,
                      ),
                    ),
                  ),
                ),
              if (recoveryCards.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => RecoveryCardWidget(action: recoveryCards[index]),
                    childCount: recoveryCards.length,
                  ),
                ),

              // Today's Top 3 Priorities
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Priorities Today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_task, size: 16),
                        label: const Text('Add Task'),
                        onPressed: widget.onQuickTask,
                      ),
                    ],
                  ),
                ),
              ),

              if (topPriorities.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'No top priorities chosen for today. Tap "+ Quick Task" to set your focus.',
                      style: TextStyle(color: AppTheme.mutedGray),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = topPriorities[index];
                      final isCompleted = task.status == TaskStatus.completed;

                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: isCompleted,
                            activeColor: AppTheme.sereneTeal,
                            onChanged: (_) => db.toggleTaskComplete(task.id),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            task.nextAction.isNotEmpty
                                ? 'Next action: ${task.nextAction}'
                                : '${task.estimateMinutes} mins',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Chip(
                            label: Text(
                              task.importance.name.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: task.importance == TaskImportance.urgent
                                ? AppTheme.gentleRose.withOpacity(0.15)
                                : AppTheme.sereneTeal.withOpacity(0.1),
                          ),
                        ),
                      );
                    },
                    childCount: topPriorities.length,
                  ),
                ),

              // Daily Habits & Spiritual Devotions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Daily Routines & Devotions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routine = routines[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          routine.isCompletedToday
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: routine.isCompletedToday ? AppTheme.sereneTeal : AppTheme.mutedGray,
                        ),
                        title: Text(
                          routine.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: routine.isCompletedToday ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          'Target: ${routine.preferredTimeLocal} (${routine.targetDurationMins}m)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: OutlinedButton(
                          child: Text(routine.isCompletedToday ? 'Done' : 'Mark Done'),
                          onPressed: () => db.toggleRoutineCompleted(routine.id),
                        ),
                      ),
                    );
                  },
                  childCount: routines.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}
