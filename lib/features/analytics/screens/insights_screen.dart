import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final allTasks = db.getTasks();
        final completedTasks = allTasks.where((t) => t.status == TaskStatus.completed).toList();
        final activeTasks = allTasks.where((t) => t.status != TaskStatus.completed).toList();
        final urgentTasks = activeTasks.where((t) => t.importance == TaskImportance.urgent || t.isTopPriority).toList();

        final accounts = db.getFinancialAccounts();
        final totalBalanceKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);
        final incomeSources = db.getIncomeSources();
        final totalExpectedIncomeKobo = incomeSources.fold<int>(0, (sum, s) => sum + s.expectedMonthlyKobo);
        final totalReceivedIncomeKobo = incomeSources.fold<int>(0, (sum, s) => sum + s.receivedKobo);

        final budgets = db.getBudgets();
        final totalBudgetKobo = budgets.fold<int>(0, (sum, b) => sum + b.allocatedKobo);
        final totalSpentKobo = budgets.fold<int>(0, (sum, b) => sum + b.spentKobo);

        final prayers = db.getPrayerSessions();
        final answeredPrayers = prayers.where((p) => p.isAnswered).toList();
        final fastingPlans = db.getFastPlans();
        final sleepLogs = db.getSleepLogs();
        final notes = db.getNotes();
        final reviews = db.getReviews();

        // Calculate Executive Score
        final double taskScore = allTasks.isNotEmpty ? (completedTasks.length / allTasks.length) : 0.7;
        final double budgetScore = totalBudgetKobo > 0 ? (1.0 - (totalSpentKobo / totalBudgetKobo).clamp(0.0, 1.0)) : 0.8;
        final double spiritualScore = prayers.isNotEmpty ? (answeredPrayers.length / prayers.length).clamp(0.4, 1.0) : 0.8;
        final double overallReadinessScore = ((taskScore * 0.35 + budgetScore * 0.25 + spiritualScore * 0.20 + 0.20) * 100).clamp(10, 100);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              'Intelligence & Audit',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white70),
                tooltip: 'Copy Executive Brief',
                onPressed: () => _copyExecutiveBrief(context, db, overallReadinessScore.toInt()),
              ),
              IconButton(
                icon: const Icon(Icons.add_task, color: Color(0xFFF97316)),
                tooltip: 'Start Sunday Review Wizard',
                onPressed: () => _showReviewWizard(context),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFF0F172A),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFF97316),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFF97316),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.speed, size: 18), text: 'Scorecard'),
                    Tab(icon: Icon(Icons.auto_stories, size: 18), text: 'Sunday Review'),
                    Tab(icon: Icon(Icons.history_edu, size: 18), text: 'Archive'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: BALANCED SCORECARD & KPIS
              _buildScorecardTab(
                context,
                overallScore: overallReadinessScore.toInt(),
                activeTasks: activeTasks,
                completedTasks: completedTasks,
                urgentTasks: urgentTasks,
                totalBalanceKobo: totalBalanceKobo,
                totalExpectedIncomeKobo: totalExpectedIncomeKobo,
                totalReceivedIncomeKobo: totalReceivedIncomeKobo,
                totalBudgetKobo: totalBudgetKobo,
                totalSpentKobo: totalSpentKobo,
                prayers: prayers,
                answeredPrayers: answeredPrayers,
                fastingPlans: fastingPlans,
                sleepLogs: sleepLogs,
                notes: notes,
              ),

              // TAB 2: SUNDAY REVIEW CADENCE WIZARD
              _buildSundayReviewTab(context, db),

              // TAB 3: REVIEW ARCHIVE & AUDIT LOG
              _buildArchiveTab(context, reviews),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: BALANCED SCORECARD
  // ==========================================
  Widget _buildScorecardTab(
    BuildContext context, {
    required int overallScore,
    required List<Task> activeTasks,
    required List<Task> completedTasks,
    required List<Task> urgentTasks,
    required int totalBalanceKobo,
    required int totalExpectedIncomeKobo,
    required int totalReceivedIncomeKobo,
    required int totalBudgetKobo,
    required int totalSpentKobo,
    required List<PrayerSession> prayers,
    required List<PrayerSession> answeredPrayers,
    required List<FastPlan> fastingPlans,
    required List<SleepLog> sleepLogs,
    required List<OmniNote> notes,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Executive Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF97316).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 12, color: Color(0xFFF97316)),
                        SizedBox(width: 4),
                        Text(
                          'HENRY ADELEKE • STRATEGIC AUDIT',
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Review Wizard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _showReviewWizard(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Holistic Health Index',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$overallScore%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EXECUTIVE ALIGNED',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Persistent real-time synthesis of Operations, Finances, Devotion & Vitality.',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: overallScore / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white12,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      const Icon(Icons.analytics, color: Colors.white, size: 28),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Four Core Executive Pillars',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),

        // PILLAR 1: OPERATIONS & EXECUTION
        _buildPillarCard(
          title: 'Operations & Execution',
          badge: 'DELIVERY',
          badgeColor: AppTheme.colorBems,
          icon: Icons.business_center,
          metrics: [
            _PillarMetric('Active Tasks', '${activeTasks.length}', const Color(0xFFF59E0B)),
            _PillarMetric('Completed', '${completedTasks.length}', const Color(0xFF10B981)),
            _PillarMetric('Top Priority', '${urgentTasks.length}', const Color(0xFFEF4444)),
          ],
          footer: '${completedTasks.length} / ${activeTasks.length + completedTasks.length} overall tasks cleared with verified persistence.',
        ),

        const SizedBox(height: 12),

        // PILLAR 2: FINANCIAL STEWARDSHIP
        _buildPillarCard(
          title: 'Financial Stewardship',
          badge: 'LIQUIDITY',
          badgeColor: const Color(0xFF059669),
          icon: Icons.account_balance_wallet,
          metrics: [
            _PillarMetric('Net Balance', MoneyFormatter.formatKobo(totalBalanceKobo), const Color(0xFF0F172A), isBlurrable: true),
            _PillarMetric('Budget Spent', MoneyFormatter.formatKobo(totalSpentKobo), const Color(0xFFDC2626)),
            _PillarMetric('Envelope Limit', MoneyFormatter.formatKobo(totalBudgetKobo), const Color(0xFF2563EB)),
          ],
          footer: totalSpentKobo <= totalBudgetKobo
              ? '✅ Spending envelope under control with ${MoneyFormatter.formatKobo(totalBudgetKobo - totalSpentKobo)} surplus buffer.'
              : '⚠️ Budget limit exceeded by ${MoneyFormatter.formatKobo(totalSpentKobo - totalBudgetKobo)}.',
        ),

        const SizedBox(height: 12),

        // PILLAR 3: SPIRITUAL SANCTUARY
        _buildPillarCard(
          title: 'Spiritual Life & Sanctuary',
          badge: 'COVENANT',
          badgeColor: const Color(0xFF7C3AED),
          icon: Icons.church,
          metrics: [
            _PillarMetric('Fasting Days', '${fastingPlans.length} Scheduled', const Color(0xFFF97316)),
            _PillarMetric('Prayers Answered', '${answeredPrayers.length}/${prayers.length}', const Color(0xFF7C3AED)),
            _PillarMetric('Revelations', '${notes.length}', const Color(0xFF0284C7)),
          ],
          footer: fastingPlans.isNotEmpty
              ? '${fastingPlans.length} fasting intervals scheduled in covenant calendar. Revelations synced.'
              : 'Dedicated prayer list with ${answeredPrayers.length} verified answered praise reports.',
        ),

        const SizedBox(height: 12),

        // PILLAR 4: VITALITY & REST
        _buildPillarCard(
          title: 'Vitality, Sleep & Rest',
          badge: 'ENERGY',
          badgeColor: const Color(0xFF0284C7),
          icon: Icons.nightlight_round,
          metrics: [
            _PillarMetric('Sleep Logs', '${sleepLogs.length}', const Color(0xFF0284C7)),
            _PillarMetric('Rest Score', sleepLogs.isNotEmpty ? '${sleepLogs.first.wellbeingScore}/5 ⭐' : '4.5/5 ⭐', const Color(0xFF10B981)),
            _PillarMetric('Weekly Cadence', '${fastingPlans.length} fasts scheduled', const Color(0xFF64748B)),
          ],
          footer: 'Cross-midnight sleep architecture ensures circadian rest without negative timestamp discrepancies.',
        ),

        const SizedBox(height: 24),

        // Top Strategic Needle-Movers List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Strategic Needle-Movers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            Text(
              '${urgentTasks.length} High Priority',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (urgentTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: const Center(
              child: Text(
                'All high priority deliverables cleared. Add new strategic goals via Sunday Review.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ...urgentTasks.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                    child: const Icon(Icons.star, color: Color(0xFFEF4444), size: 20),
                  ),
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(t.nextAction, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                    tooltip: 'Mark Complete',
                    onPressed: () => LocalDatabase.instance.toggleTaskComplete(t.id),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<_PillarMetric> metrics,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: badgeColor.withOpacity(0.12),
                child: Icon(icon, size: 18, color: badgeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: metrics.map((m) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    if (m.isBlurrable)
                      PrivacyBlurWrapper(
                        child: Text(
                          m.value,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: m.color),
                        ),
                      )
                    else
                      Text(
                        m.value,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: m.color),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footer,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: SUNDAY REVIEW CADENCE WIZARD
  // ==========================================
  Widget _buildSundayReviewTab(BuildContext context, LocalDatabase db) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_repeat, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Executive Sunday Review Cadence',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Every Sunday evening, conduct this 4-step strategic audit to clear mental cache, evaluate financial burn, review spiritual discipline, and align next week’s top 3 milestones.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFC2410C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start 4-Step Review Now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showReviewWizard(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Guided 4-Step Framework',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),

        _buildStepGuideCard(
          step: '1',
          title: 'Operational Clearance & Deliverables',
          description: 'Review active and completed tasks across Bems Group, Henovate & Personal. Close out completed actions or reschedule realistic next steps.',
          icon: Icons.checklist_rtl,
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 10),
        _buildStepGuideCard(
          step: '2',
          title: 'Financial Stewardship & Budget Audit',
          description: 'Inspect recorded SMS alert postings, categorize expenses to envelope budgets, and review monthly revenue intake across income sources.',
          icon: Icons.account_balance,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 10),
        _buildStepGuideCard(
          step: '3',
          title: 'Covenant & Vitality Inventory',
          description: 'Record answered prayer reports, verify upcoming fasting calendar days, check average sleep duration, and wardrobe rotation for Sunday service.',
          icon: Icons.favorite,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 10),
        _buildStepGuideCard(
          step: '4',
          title: 'Next Week Top 3 Strategic Milestones',
          description: 'Define the 3 non-negotiable needle-movers for the coming week. The system will automatically inject them as top-priority tasks in your workspaces.',
          icon: Icons.flag,
          color: const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildStepGuideCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              step,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: REVIEW ARCHIVE & AUDIT LOG
  // ==========================================
  Widget _buildArchiveTab(BuildContext context, List<ReviewEntry> reviews) {
    final filteredReviews = _selectedFilter == 'all'
        ? reviews
        : reviews.where((r) => r.kind.toLowerCase() == _selectedFilter).toList();

    return Column(
      children: [
        // Filter Chips Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Weekly', 'weekly'),
              const SizedBox(width: 8),
              _buildFilterChip('Monthly', 'monthly'),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _showReviewWizard(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List of Reviews
        Expanded(
          child: filteredReviews.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No saved reviews in this filter.\nTap "+ New Review" to start Sunday audit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (ctx, idx) {
                    final review = filteredReviews[idx];
                    return _buildReviewArchiveCard(context, review);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
      selectedColor: const Color(0xFFF97316),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildReviewArchiveCard(BuildContext context, ReviewEntry review) {
    final isWeekly = review.kind.toLowerCase() == 'weekly';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isWeekly ? const Color(0xFFF97316).withOpacity(0.12) : const Color(0xFF2563EB).withOpacity(0.12),
          child: Icon(
            isWeekly ? Icons.event_repeat : Icons.calendar_month,
            color: isWeekly ? const Color(0xFFF97316) : const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        title: Text(
          review.summary,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          'Completed: ${AppDateUtils.formatShortDate(review.completedAt)} • ${review.kind.toUpperCase()}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'Key Accomplishments & Wins:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669)),
                ),
                const SizedBox(height: 4),
                Text(
                  review.accomplishments,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lessons Learned & Adjustments:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFEA580C)),
                ),
                const SizedBox(height: 4),
                Text(
                  review.lessons,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '${review.summary}\n\nAccomplishments:\n${review.accomplishments}\n\nLessons:\n${review.lessons}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Delete Review',
                      onPressed: () {
                        LocalDatabase.instance.deleteReview(review.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review removed')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SUNDAY REVIEW 4-STEP WIZARD DIALOG
  // ==========================================
  void _showReviewWizard(BuildContext context) {
    int currentStep = 0;
    final summaryCtrl = TextEditingController(text: 'Week ${((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).ceil()} Strategic Review');
    final accomplishmentsCtrl = TextEditingController();
    final lessonsCtrl = TextEditingController();
    final topGoal1Ctrl = TextEditingController();
    final topGoal2Ctrl = TextEditingController();
    final topGoal3Ctrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFF97316).withOpacity(0.15),
                    child: const Icon(Icons.rate_review, color: Color(0xFFF97316), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sunday Review • Step ${currentStep + 1} of 4',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Progress Bar
                      LinearProgressIndicator(
                        value: (currentStep + 1) / 4,
                        color: const Color(0xFFF97316),
                        backgroundColor: const Color(0xFFF97316).withOpacity(0.15),
                      ),
                      const SizedBox(height: 16),

                      // STEP 0: TITLE & WINS
                      if (currentStep == 0) ...[
                        const Text(
                          'Step 1: Operational Wins & Clearance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Name this review period and summarize your major wins and completed projects across Bems Group & Henovate.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: summaryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Review Period / Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: accomplishmentsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Major Accomplishments (bullet points)',
                            hintText: '• Completed enterprise contract review\n• Maintained 16h fasting window\n• Outfits pressed for full week',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ]

                      // STEP 1: LESSONS & ADJUSTMENTS
                      else if (currentStep == 1) ...[
                        const Text(
                          'Step 2: Financial & Operational Adjustments',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'What bottlenecks occurred this week? Any budget variances, unexpected expenses, or habit friction to correct?',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: lessonsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Lessons Learned & Systems Corrections',
                            hintText: '• Keep smartphone outside bedroom by 10:30 PM\n• Rebalance operational cash reserves for Q4',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ]

                      // STEP 2: NEXT WEEK TOP 3 STRATEGIC GOALS
                      else if (currentStep == 2) ...[
                        const Text(
                          'Step 3: Top 3 Strategic Needle-Movers',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter the 3 non-negotiables for the upcoming week. These will automatically be converted to Top Priority tasks.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: topGoal1Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Strategic Goal #1 (Highest Priority)',
                            prefixIcon: Icon(Icons.looks_one, color: Color(0xFFEF4444)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: topGoal2Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Strategic Goal #2',
                            prefixIcon: Icon(Icons.looks_two, color: Color(0xFFF97316)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: topGoal3Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Strategic Goal #3',
                            prefixIcon: Icon(Icons.looks_3, color: Color(0xFF2563EB)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ]

                      // STEP 3: FINAL SYNTHESIS & COMMIT
                      else if (currentStep == 3) ...[
                        const Text(
                          'Step 4: Final Executive Confirmation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Review will be persistently recorded to your audit archive and top goals will be converted into active workspace tasks.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(summaryCtrl.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('Wins: ${accomplishmentsCtrl.text.isEmpty ? "Consistent execution" : accomplishmentsCtrl.text}', style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 6),
                              Text('Lessons: ${lessonsCtrl.text.isEmpty ? "Maintain discipline" : lessonsCtrl.text}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (currentStep > 0)
                  TextButton(
                    child: const Text('Back'),
                    onPressed: () => setDialogState(() => currentStep--),
                  )
                else
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                if (currentStep < 3)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                    child: const Text('Next Step', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => setDialogState(() => currentStep++),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    child: const Text('Save & Inject Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final now = DateTime.now();
                      final db = LocalDatabase.instance;

                      // 1. Save Review Entry
                      db.saveReview(
                        ReviewEntry(
                          id: 'rev-${now.millisecondsSinceEpoch}',
                          kind: 'weekly',
                          completedAt: now,
                          summary: summaryCtrl.text.trim().isEmpty ? 'Sunday Strategic Review' : summaryCtrl.text.trim(),
                          accomplishments: accomplishmentsCtrl.text.trim().isEmpty ? 'Consistent progress logged across workspaces' : accomplishmentsCtrl.text.trim(),
                          lessons: lessonsCtrl.text.trim().isEmpty ? 'Consolidate routines and focus on high-leverage outcomes' : lessonsCtrl.text.trim(),
                        ),
                      );

                      // 2. Inject Top Goals as High Priority Tasks
                      final goals = [
                        topGoal1Ctrl.text.trim(),
                        topGoal2Ctrl.text.trim(),
                        topGoal3Ctrl.text.trim(),
                      ].where((g) => g.isNotEmpty).toList();

                      for (int i = 0; i < goals.length; i++) {
                        db.upsertTask(
                          Task(
                            id: 'task-goal-${now.millisecondsSinceEpoch}-$i',
                            workspaceId: AppConstants.workspaceBemsId,
                            title: goals[i],
                            nextAction: 'Weekly priority milestone # ${i + 1} from Sunday Review',
                            importance: TaskImportance.urgent,
                            isTopPriority: true,
                            scheduledDate: now.add(Duration(days: i + 1)),
                            createdAt: now,
                          ),
                        );
                      }

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('Sunday Review recorded & ${goals.length} strategic tasks injected!'),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // EXPORT EXECUTIVE BRIEF TO CLIPBOARD
  // ==========================================
  void _copyExecutiveBrief(BuildContext context, LocalDatabase db, int overallScore) {
    final tasks = db.getTasks();
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final accounts = db.getFinancialAccounts();
    final balance = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);
    final prayers = db.getPrayerSessions();
    final answered = prayers.where((p) => p.isAnswered).length;

    final brief = '''
# EXECUTIVE BRIEF • HENRY ADELEKE
Date: ${AppDateUtils.formatFullDate(DateTime.now())}
Strategic Health Index: $overallScore%

## 1. Operations & Deliverables
- Total Tasks: ${tasks.length} (Cleared: $completed, Pending: ${tasks.length - completed})
- Top Priority Milestones: ${tasks.where((t) => t.isTopPriority).length}

## 2. Financial Stewardship
- Net Total Balance: ${MoneyFormatter.formatKobo(balance)}
- Recorded Ledger Postings: ${db.getLedgerTransactions().length}

## 3. Spiritual Sanctuary & Vitality
- Answered Prayer Petitions: $answered / ${prayers.length}
- Revelation Notes Logged: ${db.getNotes().length}
''';

    Clipboard.setData(ClipboardData(text: brief));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E293B),
        content: Text('Executive brief copied to clipboard in Markdown format.'),
      ),
    );
  }
}

class _PillarMetric {
  final String label;
  final String value;
  final Color color;
  final bool isBlurrable;

  const _PillarMetric(this.label, this.value, this.color, {this.isBlurrable = false});
}
