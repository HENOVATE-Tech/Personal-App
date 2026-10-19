import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
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
import '../../bible/screens/bible_reader_screen.dart';
import '../../../core/services/api_service.dart';
import '../../more/screens/more_hub_screen.dart';
import '../../finance/screens/budget_management_screen.dart';
import '../../../core/services/sms_ingestion_service.dart';

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
  late final PageController _financialPageController;
  int _currentFinancialSlide = 0;

  @override
  void initState() {
    super.initState();
    _financialPageController = PageController();
    // Fire non-blocking background REST API sync with Render on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiService.instance.syncAll(LocalDatabase.instance);
    });
  }

  @override
  void dispose() {
    _financialPageController.dispose();
    super.dispose();
  }

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
        // 2. Recovery Cards
        final recoveryCards = CommitmentRecoveryEngine.instance.evaluateCommitments(referenceDate: now);

        // 4. Financial Calculations & Slides
        final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final accounts = db.getFinancialAccounts();
        final totalBalanceKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);
        final budgets = db.getBudgets(periodMonthYear: currentPeriod);
        final totalBudgetKobo = budgets.fold<int>(0, (sum, b) => sum + b.allocatedKobo);
        final totalSpentKobo = db.getMonthTotalExpenseKobo(periodMonthYear: currentPeriod);
        final remainingAllowanceKobo = (totalBudgetKobo - totalSpentKobo).clamp(0, double.infinity).toInt();

        final incomeSources = db.getIncomeSources(workspaceId: _selectedWorkspaceId);
        final totalExpectedIncomeKobo = incomeSources.fold<int>(0, (s, i) => s + i.expectedMonthlyKobo);
        final totalReceivedIncomeKobo = incomeSources.fold<int>(0, (s, i) => s + i.receivedKobo);
        final effectiveDisplayName = profile.displayName == 'Owner' || profile.displayName.isEmpty
            ? 'Henry Adeleke'
            : profile.displayName;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 110 + MediaQuery.of(context).padding.bottom),
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
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFFFECE5),
                              child: Icon(Icons.person, color: AppTheme.coralPrimary, size: 22),
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
                                    effectiveDisplayName,
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

                // Hero Sunset Mesh Gradient Card with Swipeable Financial Carousel
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
                          effectiveDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Swipeable Financial Carousel (Available Funds, Budget vs Spent, Left to Spend, Income Streams)
                        SizedBox(
                          height: 156,
                          child: PageView(
                            controller: _financialPageController,
                            onPageChanged: (idx) => setState(() => _currentFinancialSlide = idx),
                            children: [
                              _buildSlideAvailableFunds(totalBalanceKobo),
                              _buildSlideBudgetVsSpent(totalSpentKobo, totalBudgetKobo, currentPeriod),
                              _buildSlideRemainingAllowance(remainingAllowanceKobo, totalBudgetKobo),
                              _buildSlideIncomeStreams(incomeSources, totalExpectedIncomeKobo, totalReceivedIncomeKobo),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Carousel Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final isChosen = i == _currentFinancialSlide;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isChosen ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isChosen ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // Compact Quick Shortcuts Directly Under Hero Card (Exactly requested 6 items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Shortcuts & Hubs',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MoreHubScreen()),
                          );
                        },
                        child: const Text(
                          'View All →',
                          style: TextStyle(
                            color: AppTheme.coralPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Omni Notes',
                            subtitle: 'Prophecy, Bible & Vision',
                            icon: Icons.edit_note_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotesWorkstationScreen()),
                            ),
                          ),
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Devotions & Disciples',
                            subtitle: 'Prayer, Scripture & Fasting',
                            icon: Icons.auto_stories_rounded,
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SpiritualOverviewScreen()),
                            ),
                          ),
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Lifestyle & Wardrobe',
                            subtitle: 'Care, Chores & Outfits',
                            icon: Icons.checkroom_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LifestyleHubScreen()),
                            ),
                          ),
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Knowledge & Reviews',
                            subtitle: 'Books, Synthesis & Audits',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ReadingLibraryScreen()),
                            ),
                          ),
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Health & Sleep',
                            subtitle: 'Vitals & Night Rest Log',
                            icon: Icons.bedtime_rounded,
                            color: const Color(0xFF06B6D4),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HealthHubScreen()),
                            ),
                          ),
                          _buildCompactShortcutCard(
                            context,
                            width: itemWidth,
                            title: 'Intelligence & Audit',
                            subtitle: 'Ledger Verification & Sync',
                            icon: Icons.insights_rounded,
                            color: const Color(0xFFEF4444),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const InsightsScreen()),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Workspace Switcher Filter (With + Add / Edit Capabilities)
                WorkspaceSelector(
                  selectedWorkspaceId: _selectedWorkspaceId,
                  onWorkspaceChanged: (id) => setState(() => _selectedWorkspaceId = id),
                ),

                // Smart SMS Bank Ingestion Section (Tracks both Credit & Debit with approval queue)
                _buildSmartSmsApprovalSection(context, db),

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
                        icon: Icons.menu_book,
                        label: 'Holy Bible',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BibleReaderScreen()),
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

                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MoreHubScreen()),
                      );
                    },
                    icon: const Icon(Icons.explore_outlined, size: 16, color: AppTheme.coralPrimary),
                    label: const Text(
                      'Explore All Modules in More Hub →',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.coralPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  // --- Financial Hero Carousel Slides ---

  Widget _buildSlideAvailableFunds(int totalBalanceKobo) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Liquid Funds',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
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
              Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textTertiary, size: 26),
            ],
          ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: widget.onQuickExpense,
                child: const Text('Quick Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideBudgetVsSpent(int totalSpentKobo, int totalBudgetKobo, String currentPeriod) {
    final isOver = totalSpentKobo > totalBudgetKobo && totalBudgetKobo > 0;
    final pct = totalBudgetKobo > 0 ? ((totalSpentKobo / totalBudgetKobo) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spent vs Budget',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Period • $currentPeriod',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOver ? 'OVER BUDGET' : '$pct% SPENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isOver ? Colors.red : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PrivacyBlurWrapper(
                    child: Text(
                      'Spent: ${MoneyFormatter.formatKobo(totalSpentKobo)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ),
                  PrivacyBlurWrapper(
                    child: Text(
                      'Budget: ${MoneyFormatter.formatKobo(totalBudgetKobo)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalBudgetKobo > 0 ? (totalSpentKobo / totalBudgetKobo).clamp(0.0, 1.0) : 0.0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver ? Colors.red : AppTheme.coralPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideRemainingAllowance(int remainingKobo, int totalBudgetKobo) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount Left to Spend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Remaining Discretionary Allowance',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Icon(Icons.savings_outlined, color: Color(0xFF10B981), size: 26),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: PrivacyBlurWrapper(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      MoneyFormatter.formatKobo(remainingKobo),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: remainingKobo > 0 ? const Color(0xFF047857) : Colors.red,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: AppTheme.darkCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
                  );
                },
                child: const Text('Budgets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideIncomeStreams(List<IncomeSource> sources, int totalExpectedKobo, int totalReceivedKobo) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income Streams & Targets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sources.length} Active Revenue Sources',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Icon(Icons.trending_up, color: Color(0xFF059669), size: 26),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrivacyBlurWrapper(
                      child: Text(
                        'Received: ${MoneyFormatter.formatKobo(totalReceivedKobo)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    PrivacyBlurWrapper(
                      child: Text(
                        'Target: ${MoneyFormatter.formatKobo(totalExpectedKobo)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
                  );
                },
                child: const Text('Income Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Compact Shortcut Card ---

  Widget _buildCompactShortcutCard(
    BuildContext context, {
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.textTertiary),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Smart SMS Approval Queue (Credit + Debit Ingestion) ---

  Widget _buildSmartSmsApprovalSection(BuildContext context, LocalDatabase db) {
    final pending = db.getPendingSmsDebitAlerts();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: pending.isNotEmpty ? const Color(0xFFFFCC80) : const Color(0xFFE5E7EB),
          width: pending.isNotEmpty ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: pending.isNotEmpty ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sms_outlined,
                        size: 18,
                        color: pending.isNotEmpty ? const Color(0xFFEA580C) : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Smart SMS Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pending.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pending.length} PENDING',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showSimulateSmsDialog(context, db),
                icon: const Icon(Icons.flash_on, size: 14, color: AppTheme.coralPrimary),
                label: const Text(
                  'Test Alert',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.coralPrimary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (pending.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Tracking live Credit & Debit banking alerts (GTB, Access, Zenith, Kuda). Tap "Test Alert" to simulate an SMS.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...pending.map((alert) {
              final isCredit = !alert.isDebit;
              const isCreditColor = Color(0xFF10B981);
              const isDebitColor = Color(0xFFEF4444);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 16,
                              color: isCredit ? isCreditColor : isDebitColor,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCredit ? 'CREDIT INFLOW' : 'DEBIT EXPENSE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isCredit ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              alert.sender,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '${isCredit ? "+" : "-"}${MoneyFormatter.formatKobo(alert.amountKobo)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isCredit ? isCreditColor : isDebitColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.memo,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acct: ${alert.accountLast4 != null ? "***${alert.accountLast4}" : "GTBank"} • Suggestion: ${isCredit ? "Income" : "Expense"} ledger account',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            db.dismissSmsAlert(alert.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Alert disapproved and dismissed.')),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('✕ Disapprove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            db.approveSmsAlert(alert.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ Approved ${MoneyFormatter.formatKobo(alert.amountKobo)} posted to Verified Ledger!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('✓ Approve & Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showSimulateSmsDialog(BuildContext context, LocalDatabase db) {
    final smsCtrl = TextEditingController(
      text: 'Credit: Acct: 0123***456 Amt: NGN 350,000.00 Desc: Henovate Tech Retainer Inflow',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.sms_rounded, color: AppTheme.coralPrimary),
              SizedBox(width: 8),
              Text('Simulate SMS Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste a bank SMS or choose a test preset to verify the Credit/Debit parser & approval queue:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: smsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter bank SMS text...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quick Test Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('GTB Credit ₦350,000', style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFE8F5E9),
                      onPressed: () {
                        smsCtrl.text = 'Credit: Acct: 0123***456 Amt: NGN 350,000.00 Desc: Henovate Tech Retainer Inflow';
                      },
                    ),
                    ActionChip(
                      label: const Text('Access Debit ₦18,500', style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFEE2E2),
                      onPressed: () {
                        smsCtrl.text = 'Debit: Acct: 0123***456 Amt: NGN 18,500.00 Desc: POS 104234 Ebeano Supermarket Lekki';
                      },
                    ),
                    ActionChip(
                      label: const Text('Zenith Credit ₦1,200,000', style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFE8F5E9),
                      onPressed: () {
                        smsCtrl.text = 'Your Acct 102***890 has been credited with NGN 1,200,000.00 from Bems Group Exec Salary';
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final raw = smsCtrl.text.trim();
                if (raw.isEmpty) return;
                final alert = SmsIngestionService.parseDebitAlert(
                  sender: 'GTBank',
                  body: raw,
                  timestamp: DateTime.now(),
                );
                if (alert != null) {
                  db.addSmsDebitAlert(alert);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Captured ${alert.isDebit ? "Debit" : "Credit"} alert for ${MoneyFormatter.formatKobo(alert.amountKobo)}. Ready for approval!'),
                      backgroundColor: alert.isDebit ? Colors.orange.shade800 : const Color(0xFF10B981),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not parse bank amount from SMS text.')),
                  );
                }
              },
              child: const Text('Capture SMS'),
            ),
          ],
        );
      },
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
