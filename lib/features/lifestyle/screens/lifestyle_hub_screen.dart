import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class LifestyleHubScreen extends StatelessWidget {
  const LifestyleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final careItems = db.getCareChecklist();
        final chores = db.getChores();
        final outfitPlans = db.getOutfitPlans();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppTheme.creamCanvas,
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
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
                                  'Personal Life',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Care & Wardrobe',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily hygiene, chores and 7-day friction-free Sunday outfit planning',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Rounded Pill TabBar
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppTheme.darkCharcoal,
                          unselectedLabelColor: Colors.white,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Care'),
                            Tab(text: 'Chores'),
                            Tab(text: 'Wardrobe'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 1. Daily Personal Care Tab
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        children: [
                          const Text(
                            'Daily Personal Care',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkCharcoal),
                          ),
                          const SizedBox(height: 12),
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
                                      child: c.isCompleted
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
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
                                ],
                              ),
                            );
                          }),
                        ],
                      ),

                      // 2. Chores Tab
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        children: [
                          const Text(
                            'Household & Order Chores',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkCharcoal),
                          ),
                          const SizedBox(height: 12),
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
                                      child: chore.isCompleted
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
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
                                          'Frequency: ${chore.frequency} • ${chore.estimatedMins}m est.',
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
                                ],
                              ),
                            );
                          }),
                        ],
                      ),

                      // 3. Sunday Wardrobe Planner Tab (BR-04)
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                color: AppTheme.peachPillBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.coralPrimary,
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
                  Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.darkCharcoal,
                    ),
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
            GestureDetector(
              onTap: () => _showEditOutfitDialog(context, day, existing, db, now),
              child: Container(
                width: 34,
                height: 34,
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

  void _showEditOutfitDialog(
    BuildContext context,
    String day,
    OutfitPlan? existing,
    LocalDatabase db,
    DateTime now,
  ) {
    final controller = TextEditingController(text: existing?.outfitDescription ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Outfit for $day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Outfit description',
            hintText: 'e.g. Navy suit, white shirt, black leather shoes',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                db.upsertOutfitPlan(
                  OutfitPlan(
                    id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    dayOfWeek: day,
                    calendarDate: now,
                    outfitDescription: controller.text.trim(),
                  ),
                );
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
