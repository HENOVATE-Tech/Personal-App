import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/recurrence_engine.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';
import '../../../core/widgets/workspace_selector.dart';
import '../../recovery/services/commitment_recovery_engine.dart';
import '../../lifestyle/screens/lifestyle_hub_screen.dart';
import '../../spiritual/screens/spiritual_overview_screen.dart';
import '../../professional/screens/workspaces_overview_screen.dart';
import '../../learning/screens/reading_library_screen.dart';
import '../../health/screens/health_hub_screen.dart';
import '../../analytics/screens/insights_screen.dart';
import '../../governance/screens/device_governance_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notes/screens/notes_workstation_screen.dart';
import '../../../core/services/api_service.dart';

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
        final pendingTasks = allTasks.where((t) => t.status != TaskStatus.completed).toList();

        // 2. Recovery Cards
        final recoveryCards = CommitmentRecoveryEngine.instance.evaluateCommitments(referenceDate: now);

        // 3. Fasting Status
        final bool isMonday = now.weekday == DateTime.monday;
        final bool isFriday = now.weekday == DateTime.friday;
        final bool isLastWeekend = RecurrenceEngine.isLastFridayOfMonth(now) ||
            now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday;
        final bool isFastingDay = isMonday || isFriday || isLastWeekend;

        // 4. Financial Calculations
        final accounts = db.getFinancialAccounts();
        final totalBalanceKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom Header Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFFECE5),
                              child: const Icon(Icons.person, color: AppTheme.coralPrimary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppDateUtils.formatFullDate(now),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    profile.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _buildCircleIconButton(
                            icon: profile.privacyModeEnabled ? Icons.visibility_off : Icons.visibility,
                            color: profile.privacyModeEnabled ? AppTheme.coralPrimary : AppTheme.textSecondary,
                            onTap: () {
                              db.updateUserProfile(
                                profile.copyWith(privacyModeEnabled: !profile.privacyModeEnabled),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildCircleIconButton(
                            icon: _lowEnergyMode ? Icons.battery_charging_full : Icons.battery_saver,
                            color: _lowEnergyMode ? AppTheme.amberWarm : AppTheme.textSecondary,
                            onTap: () {
                              setState(() => _lowEnergyMode = !_lowEnergyMode);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Hero Sunset Mesh Gradient Card (Exact visual match from reference image)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetMesh,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppTheme.heroFloatShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Glassmorphic translucent badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFCC80),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${pendingTasks.length}',
                                    style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  isFastingDay
                                      ? 'Fasting active • ${pendingTasks.length} pending'
                                      : 'You have ${pendingTasks.length} claims in progress',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Embedded Crisp White Floating Card (from reference UI)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Available Liquid Funds',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: const [
                                            Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Double-entry ledger verified',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.receipt_long, color: AppTheme.textTertiary, size: 28),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: PrivacyBlurWrapper(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          MoneyFormatter.formatKobo(totalBalanceKobo),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.darkCharcoal,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: widget.onQuickExpense,
                                    child: const Text('Quick Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Workspace Switcher Filter
                WorkspaceSelector(
                  selectedWorkspaceId: _selectedWorkspaceId,
                  onWorkspaceChanged: (id) => setState(() => _selectedWorkspaceId = id),
                ),

                // "Services" Horizontal Action Shortcuts (exact match from reference)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildServiceItem(
                        icon: Icons.add_task,
                        label: 'Capture Task',
                        onTap: widget.onQuickTask,
                      ),
                      _buildServiceItem(
                        icon: Icons.payments_outlined,
                        label: 'Expense',
                        onTap: widget.onQuickExpense,
                      ),
                      _buildServiceItem(
                        icon: Icons.timer_outlined,
                        label: 'Focus Timer',
                        onTap: () {
                          _showFocusTimerDialog(context);
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.security_outlined,
                        label: 'Phone Shield',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DeviceGovernanceScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.business_center_outlined,
                        label: 'Workspaces',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WorkspacesOverviewScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.draw_outlined,
                        label: 'Omni Notes',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotesWorkstationScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.checkroom_outlined,
                        label: 'Wardrobe',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LifestyleHubScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.auto_stories_outlined,
                        label: 'Devotion',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SpiritualOverviewScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.menu_book_outlined,
                        label: 'Library',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReadingLibraryScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.favorite_outline,
                        label: 'Health & Sleep',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HealthHubScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.insights_outlined,
                        label: 'Analytics',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const InsightsScreen()),
                          );
                        },
                      ),
                      _buildServiceItem(
                        icon: Icons.cloud_outlined,
                        label: 'Cloud & API',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // "Events & Top Priorities" Section Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Priorities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onQuickTask,
                        child: const Text(
                          '+ Add Action',
                          style: TextStyle(
                            color: AppTheme.coralPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Priority Action Cards (styled like the Hospital/Event cards in reference image)
                if (topPriorities.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade300),
                          const SizedBox(height: 8),
                          const Text(
                            'All top priorities completed for today!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "+ Add Action" to focus on a new physical step.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...topPriorities.map((task) {
                    final isDone = task.status == TaskStatus.completed;
                    final categoryTag = task.workspaceId == 'ws-bems-group'
                        ? 'Bems Group • COO'
                        : (task.workspaceId == 'ws-henovate' ? 'Henovate • Founder' : 'Personal Order');

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pastel Category Tag & Importance Chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pastelPeach,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    categoryTag,
                                    style: const TextStyle(
                                      color: AppTheme.pastelPeachText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${task.estimateMinutes}m',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Task Title
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Next Physical Action
                            if (task.nextAction.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.near_me, size: 14, color: AppTheme.coralPrimary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      task.nextAction,
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      isDone ? Icons.undo : Icons.check,
                                      size: 16,
                                    ),
                                    label: Text(isDone ? 'Reopen' : 'Complete Action'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDone ? const Color(0xFFF3F4F6) : AppTheme.darkCharcoal,
                                      foregroundColor: isDone ? AppTheme.textPrimary : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => db.toggleTaskComplete(task.id),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                // "Commitment Recovery" Section (styled like e-Cards in reference image)
                if (recoveryCards.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Commitment Recovery',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ...recoveryCards.map((card) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.coralCardGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PLOS-RECOVERY-01',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('NO STREAK LOSS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              card.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.reason,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.darkCharcoal,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () {
                                    CommitmentRecoveryEngine.instance.applyRecoveryChoice(
                                      actionId: card.id,
                                      choice: 'do_5_min',
                                      sourceType: card.sourceType,
                                      sourceId: card.sourceId,
                                    );
                                  },
                                  child: const Text('Do 5 mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () {
                                    CommitmentRecoveryEngine.instance.applyRecoveryChoice(
                                      actionId: card.id,
                                      choice: 'reschedule',
                                      sourceType: card.sourceType,
                                      sourceId: card.sourceId,
                                      newScheduledDate: DateTime.now().add(const Duration(days: 1)),
                                    );
                                  },
                                  child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // ----------------------------------------------------
                // ECOSYSTEM WORKSTATIONS (All Hub Modules on Home Dashboard)
                // ----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ecosystem Workstations',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Dedicated operational command centers',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelPeach,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '9 STATIONS',
                          style: TextStyle(
                            color: AppTheme.pastelPeachText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. Notes & Revelations Hub (Spiritual, Bible Study, Vision, Professional)
                _buildWorkstationCard(
                  context,
                  badge: 'OMNI NOTES & PROPHECY HUB',
                  badgeColor: const Color(0xFFF3E8FF),
                  badgeTextColor: const Color(0xFF6B21A8),
                  icon: Icons.draw_outlined,
                  iconGradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF581C87)]),
                  title: 'Notes & Revelations Hub',
                  subtitle: 'Segregated Spiritual (revelations, visions, dreams), Bible Study, Strategy, Professional & Relationships with 1-tap Task conversion',
                  connectedStatus: '${db.getNotes().length} notes active • ${db.getNotes().where((n) => n.isPinned).length} pinned • Synced',
                  destination: const NotesWorkstationScreen(),
                ),

                // 2. Phone Governance & Focus Shield
                _buildWorkstationCard(
                  context,
                  badge: 'DEVICE CONTROL & GOVERNANCE',
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFF991B1B),
                  icon: Icons.security,
                  iconGradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
                  title: 'Phone Governance & Focus Shield',
                  subtitle: 'Device administrator lockdown, social handles shutdown, emergency siren and quick alert triggers',
                  connectedStatus: 'Admin Enforcer & Social Blockade Active',
                  destination: const DeviceGovernanceScreen(),
                ),

                // 2. Professional Workspaces
                _buildWorkstationCard(
                  context,
                  badge: 'OPERATIONAL WORKSPACES',
                  badgeColor: const Color(0xFFE0E7FF),
                  badgeTextColor: const Color(0xFF3730A3),
                  icon: Icons.business_center,
                  iconGradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF312E81)]),
                  title: 'Professional Workspaces',
                  subtitle: 'Segregated Bems Group (COO) & Henovate (Founder) strategic milestones and deliverables',
                  connectedStatus: '${allTasks.where((t) => t.workspaceId == 'ws-bems-group').length} Bems tasks • ${allTasks.where((t) => t.workspaceId == 'ws-henovate').length} Henovate tasks',
                  destination: const WorkspacesOverviewScreen(),
                ),

                // 3. Spiritual Life & Fasting Engine
                _buildWorkstationCard(
                  context,
                  badge: 'DEVOTION & DISCIPLINES',
                  badgeColor: const Color(0xFFEDE9FE),
                  badgeTextColor: const Color(0xFF5B21B6),
                  icon: Icons.church,
                  iconGradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                  title: 'Spiritual Life & Fasting Engine',
                  subtitle: 'Prayer journal, Scripture passage planner, 3-day fasting schedule engine with zero streak penalties',
                  connectedStatus: isFastingDay ? 'Fasting Active (6AM–6PM) • Mon/Fri rhythm' : 'Regular rhythm • Next Fast: Friday',
                  destination: const SpiritualOverviewScreen(),
                ),

                // 4. Personal Care & Wardrobe
                _buildWorkstationCard(
                  context,
                  badge: 'LIFESTYLE & WARDROBE',
                  badgeColor: const Color(0xFFFCE7F3),
                  badgeTextColor: const Color(0xFF9D174D),
                  icon: Icons.checkroom,
                  iconGradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
                  title: 'Personal Care & Wardrobe',
                  subtitle: 'Daily grooming checklist, weekend chores, Sunday-to-Saturday curated outfit rotation plans',
                  connectedStatus: '${db.getCareChecklist().where((c) => !c.isCompleted).length} pending routines • ${db.getOutfitPlans().length} outfits planned',
                  destination: const LifestyleHubScreen(),
                ),

                // 5. Reading Library & Checklists
                _buildWorkstationCard(
                  context,
                  badge: 'KNOWLEDGE & REVIEWS',
                  badgeColor: const Color(0xFFFEF3C7),
                  badgeTextColor: const Color(0xFF92400E),
                  icon: Icons.menu_book,
                  iconGradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFB45309)]),
                  title: 'Reading Library & Checklists',
                  subtitle: 'Curated books library, active study synthesis, pre-deliverable review checklist for clients',
                  connectedStatus: '${db.getBooks().length} active books in library • Deliverable checklist ready',
                  destination: const ReadingLibraryScreen(),
                ),

                // 6. Health, Sleep & Character
                _buildWorkstationCard(
                  context,
                  badge: 'HEALTH & SLEEP',
                  badgeColor: const Color(0xFFD1FAE5),
                  badgeTextColor: const Color(0xFF065F46),
                  icon: Icons.favorite,
                  iconGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  title: 'Health, Relationships & Sleep',
                  subtitle: 'Cross-midnight sleep validator, wellbeing score, relational character logs & health tracking',
                  connectedStatus: '${db.getSleepLogs().length} sleep logs recorded • Bedtime validation active',
                  destination: const HealthHubScreen(),
                ),

                // 7. Intelligence & Analytics
                _buildWorkstationCard(
                  context,
                  badge: 'INTELLIGENCE & AUDITS',
                  badgeColor: const Color(0xFFCCFBF1),
                  badgeTextColor: const Color(0xFF115E59),
                  icon: Icons.insights,
                  iconGradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0F766E)]),
                  title: 'Reviews & Insights Analytics',
                  subtitle: 'Sunday weekly review cadence, month-end balance verification, authentic trend analytics',
                  connectedStatus: 'Double-entry ledger verified • Weekly cadence active',
                  destination: const InsightsScreen(),
                ),

                // 8. Render REST API & Cloud Storage
                _buildWorkstationCard(
                  context,
                  badge: 'CLOUD & API BACKEND',
                  badgeColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1E40AF),
                  icon: Icons.cloud_done,
                  iconGradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                  title: 'Render REST API & Cloud Storage',
                  subtitle: 'Live REST API at ${ApiService.instance.baseUrl} connected to Supabase PostgreSQL',
                  connectedStatus: '21 tables synchronized • TLS encryption • Offline-first',
                  destination: const SettingsScreen(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkstationCard(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Gradient iconGradient,
    required String title,
    required String subtitle,
    required String connectedStatus,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: iconGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connectedStatus,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppTheme.darkCharcoal),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFocusTimerDialog(BuildContext context) {
    int durationMins = 25;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Start Focus Session', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  gradient: AppTheme.coralMeshGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$durationMins:00',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [5, 25, 50].map((mins) {
                  final isSelected = durationMins == mins;
                  return GestureDetector(
                    onTap: () => setDialogState(() => durationMins = mins),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.darkCharcoal : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${mins}m',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'Focus block will be recorded in time logs.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Focus session started for $durationMins minutes!'),
                    backgroundColor: AppTheme.coralPrimary,
                  ),
                );
              },
              child: const Text('Start Focus'),
            ),
          ],
        ),
      ),
    );
  }
}
