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
            appBar: AppBar(
              title: const Text('Care, Chores & Wardrobe'),
              bottom: const TabBar(
                indicatorColor: AppTheme.sereneTeal,
                tabs: [
                  Tab(text: 'Daily Care'),
                  Tab(text: 'Chores'),
                  Tab(text: 'Sunday Outfits'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. Daily Personal Care Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Daily Personal Care Checklist',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...careItems.map((c) {
                      return Card(
                        child: CheckboxListTile(
                          value: c.isCompleted,
                          activeColor: AppTheme.sereneTeal,
                          title: Text(
                            c.title,
                            style: TextStyle(
                              decoration: c.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text('Period: ${c.period.toUpperCase()}'),
                          onChanged: (_) => db.toggleCareItem(c.id),
                        ),
                      );
                    }),
                  ],
                ),

                // 2. Chores Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Household & Order Chores',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...chores.map((chore) {
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: chore.isCompleted,
                            activeColor: AppTheme.sereneTeal,
                            onChanged: (_) => db.toggleChoreComplete(chore.id),
                          ),
                          title: Text(
                            chore.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: chore.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text('Frequency: ${chore.frequency} • ${chore.estimatedMins}m est.'),
                          trailing: Chip(
                            label: Text(chore.isCompleted ? 'DONE' : 'DUE'),
                            backgroundColor: chore.isCompleted
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEF3C7),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                // 3. Sunday Wardrobe Planner Tab (BR-04)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      color: Color(0xFFFDF2F8),
                      child: Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Text(
                          'Sunday Wardrobe Planner (BR-04): Prepare and preview 7 outfits (Monday–Sunday) '
                          'across month and year boundaries so weekday mornings are friction-free.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9D174D)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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

      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFCE7F3),
            child: Text(
              day.substring(0, 2),
              style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            existing?.outfitDescription ?? 'No outfit set yet (Tap edit to specify)',
            style: TextStyle(
              color: existing != null ? AppTheme.slateNavy : AppTheme.mutedGray,
              fontStyle: existing != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _showEditOutfitDialog(context, day, existing, db, now),
          ),
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
