import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class LifestyleHubScreen extends StatefulWidget {
  const LifestyleHubScreen({super.key});

  @override
  State<LifestyleHubScreen> createState() => _LifestyleHubScreenState();
}

class _LifestyleHubScreenState extends State<LifestyleHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

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

  void _showAddCareItemDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String period = 'morning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Grooming & Hygiene Habit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Habit Title',
                    hintText: 'e.g. Skin hydration routine, Floss teeth, Beard oil',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: period,
                  decoration: InputDecoration(
                    labelText: 'Daily Period',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('🌅 Morning Hygiene')),
                    DropdownMenuItem(value: 'evening', child: Text('🌙 Evening Grooming')),
                    DropdownMenuItem(value: 'weekly', child: Text('📅 Weekly Self-Care')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => period = val);
                  },
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final item = CareChecklistItem(
                      id: 'care-${_uuid.v4().substring(0, 8)}',
                      title: title,
                      period: period,
                    );

                    LocalDatabase.instance.upsertCareItem(item);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String frequency = 'weekly';
    int estMins = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Household & Order Chore',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Chore Description',
                    hintText: 'e.g. Wash and fold linens, Deep clean executive desk',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: frequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'biweekly', child: Text('Bi-Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => frequency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: estMins,
                        decoration: InputDecoration(
                          labelText: 'Estimate',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 mins')),
                          DropdownMenuItem(value: 30, child: Text('30 mins')),
                          DropdownMenuItem(value: 45, child: Text('45 mins')),
                          DropdownMenuItem(value: 60, child: Text('1 hour')),
                          DropdownMenuItem(value: 120, child: Text('2 hours')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => estMins = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final chore = Chore(
                      id: 'chore-${_uuid.v4().substring(0, 8)}',
                      workspaceId: AppConstants.workspacePersonalId,
                      title: title,
                      frequency: frequency,
                      estimatedMins: estMins,
                    );

                    LocalDatabase.instance.upsertChore(chore);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Add Chore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditOutfitDialog(
    BuildContext context,
    String day,
    OutfitPlan? existing,
    LocalDatabase db,
    DateTime now,
  ) {
    final attireCtrl = TextEditingController(text: existing?.outfitDescription ?? '');
    final shoesCtrl = TextEditingController();
    final scentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Curate Outfit for $day',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attireCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Attire (Suit, Traditional/Agbada, Smart Casual)',
                    hintText: 'e.g. Navy tailored suit, crisp white spread collar shirt',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shoesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Footwear & Timepiece',
                    hintText: 'e.g. Oxblood Oxford shoes + Silver chronograph watch',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scentCtrl,
                  decoration: InputDecoration(
                    labelText: 'Fragrance / Scent of the Day',
                    hintText: 'e.g. Oud Wood / Creed Aventus',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final attire = attireCtrl.text.trim();
                    if (attire.isEmpty) return;

                    String fullDesc = attire;
                    if (shoesCtrl.text.trim().isNotEmpty) {
                      fullDesc += ' • Shoes: ${shoesCtrl.text.trim()}';
                    }
                    if (scentCtrl.text.trim().isNotEmpty) {
                      fullDesc += ' • Scent: ${scentCtrl.text.trim()}';
                    }

                    db.upsertOutfitPlan(
                      OutfitPlan(
                        id: existing?.id ?? 'outfit-${_uuid.v4().substring(0, 8)}',
                        dayOfWeek: day,
                        calendarDate: now,
                        outfitDescription: fullDesc,
                      ),
                    );
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Save Planned Outfit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final careItems = db.getCareChecklist();
        final chores = db.getChores();
        final outfitPlans = db.getOutfitPlans();

        final completedCare = careItems.where((c) => c.isCompleted).length;
        final completedChores = chores.where((c) => c.isCompleted).length;

        return Scaffold(
          backgroundColor: AppTheme.creamCanvas,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top + 16 : 56,
                      20,
                      18,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.coralMeshGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.35)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.checkroom, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lifestyle & Wardrobe',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Care, Wardrobe & Home Order',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Daily hygiene, domestic order and 7-day friction-free Sunday outfit planning',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 18),

                        // TabBar Pill
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppTheme.darkCharcoal,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Care Checklist'),
                              Tab(text: 'Home Chores'),
                              Tab(text: '7-Day Wardrobe'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Care Checklist Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Grooming & Hygiene',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkCharcoal),
                            ),
                            Text(
                              '$completedCare of ${careItems.length} routines completed',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Habit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddCareItemDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...careItems.map((c) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => db.toggleCareItem(c.id),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: c.isCompleted ? AppTheme.sereneTeal : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.isCompleted ? AppTheme.sereneTeal : AppTheme.coralPrimary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: c.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: c.isCompleted ? Colors.grey : AppTheme.darkCharcoal,
                                      decoration: c.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Period: ${c.period.toUpperCase()}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.isCompleted ? const Color(0xFFD1FAE5) : AppTheme.peachPillBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.isCompleted ? 'Done' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: c.isCompleted ? const Color(0xFF059669) : AppTheme.coralPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                              tooltip: 'Delete Habit',
                              onPressed: () => db.deleteCareItem(c.id),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                // 2. Chores Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Household & Order Chores',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkCharcoal),
                            ),
                            Text(
                              '$completedChores of ${chores.length} tasks resolved',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Chore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddChoreDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...chores.map((chore) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => db.toggleChoreComplete(chore.id),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: chore.isCompleted ? AppTheme.sereneTeal : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: chore.isCompleted ? AppTheme.sereneTeal : AppTheme.coralPrimary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: chore.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chore.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: chore.isCompleted ? Colors.grey : AppTheme.darkCharcoal,
                                      decoration: chore.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Frequency: ${chore.frequency.toUpperCase()} • ${chore.estimatedMins}m est.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: chore.isCompleted ? const Color(0xFFD1FAE5) : AppTheme.peachPillBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chore.isCompleted ? 'Done' : 'Due',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: chore.isCompleted ? const Color(0xFF059669) : AppTheme.coralPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                              tooltip: 'Delete Chore',
                              onPressed: () => db.deleteChore(chore.id),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                // 3. Sunday Wardrobe Planner Tab (BR-04)
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.peachPillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.checkroom, color: AppTheme.coralPrimary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sunday Wardrobe Planner (BR-04): Prepare and preview 7 outfits (Mon–Sun) across month and year boundaries so mornings are friction-free.',
                              style: TextStyle(fontSize: 12, color: AppTheme.coralPrimary.withOpacity(0.9), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildDefaultWeeklyOutfitRows(context, outfitPlans, db),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDefaultWeeklyOutfitRows(
    BuildContext context,
    List<OutfitPlan> savedPlans,
    LocalDatabase db,
  ) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final now = DateTime.now();

    return days.map((day) {
      final existing = savedPlans.cast<OutfitPlan?>().firstWhere(
            (p) => p?.dayOfWeek == day,
            orElse: () => null,
          );

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.floatingCardDecoration,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: day == 'Sunday' ? const Color(0xFFFEF3C7) : AppTheme.peachPillBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: day == 'Sunday' ? const Color(0xFFB45309) : AppTheme.coralPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                      ),
                      if (day == 'Sunday') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('SUNDAY SERVICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    existing?.outfitDescription ?? 'No outfit set yet (Tap edit to specify)',
                    style: TextStyle(
                      color: existing != null ? Colors.grey.shade700 : Colors.grey.shade400,
                      fontSize: 12,
                      fontStyle: existing != null ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (existing != null)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                tooltip: 'Clear Outfit',
                onPressed: () => db.deleteOutfitPlan(existing.id),
              ),
            GestureDetector(
              onTap: () => _showEditOutfitDialog(context, day, existing, db, now),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.offWhiteBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: AppTheme.darkCharcoal),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
