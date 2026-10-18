import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/recurrence_engine.dart';

class SpiritualOverviewScreen extends StatelessWidget {
  const SpiritualOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final routines = db.getRoutineTemplates().where((r) => r.category == 'Spiritual').toList();
        final prayerSessions = db.getPrayerSessions();
        final now = DateTime.now();
        final fastingSchedule = RecurrenceEngine.getFastingScheduleForMonth(year: now.year, month: now.month);

        return Scaffold(
          backgroundColor: AppTheme.creamCanvas,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
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
                                Icon(Icons.spa, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Continuous Practice',
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
                        'Spiritual Life',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sustainable relationship, quiet devotion & Scripture reflections',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Gentle Continuity Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.peachPillBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.favorite_border, color: AppTheme.coralPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gentle Continuity Guarantee',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No streaks to break. If a devotion was missed, return peacefully without penalties or guilt scores.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Devotion Slots Title
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Devotional Slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkCharcoal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...routines.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => db.toggleRoutineCompleted(r.id),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: r.isCompletedToday ? AppTheme.sereneTeal : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: r.isCompletedToday ? AppTheme.sereneTeal : AppTheme.coralPrimary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: r.isCompletedToday
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
                                    r.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: r.isCompletedToday ? Colors.grey : AppTheme.darkCharcoal,
                                      decoration: r.isCompletedToday ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${r.preferredTimeLocal} • ${r.targetDurationMins}m target',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: r.isCompletedToday ? const Color(0xFFD1FAE5) : AppTheme.peachPillBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                r.isCompletedToday ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: r.isCompletedToday ? const Color(0xFF059669) : AppTheme.coralPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                    // Fasting Schedule
                    const Text(
                      'Fasting Schedule (This Month)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Weekly Mon/Fri & monthly 3-day weekend fast (deduplicated on Friday).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fastingSchedule.map((d) {
                        final isPast = d.isBefore(DateTime(now.year, now.month, now.day));
                        final isToday = AppDateUtils.isSameDay(d, now);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.darkCharcoal
                                : (isPast ? Colors.grey.shade100 : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isToday ? AppTheme.darkCharcoal : Colors.black.withOpacity(0.06),
                            ),
                            boxShadow: isToday ? AppTheme.floatingCardDecoration.boxShadow : null,
                          ),
                          child: Text(
                            '${d.day} ${_monthShort(d.month)} (${_weekdayShort(d.weekday)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday ? Colors.white : (isPast ? Colors.grey : AppTheme.darkCharcoal),
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),
                    // Prayer Journal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prayer Journal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkCharcoal,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddPrayerDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCharcoal,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Add Entry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (prayerSessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Center(
                          child: Text(
                            'No prayer journal entries recorded yet.\nTap "+ Add Entry" to capture your reflections.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
                          ),
                        ),
                      )
                    else
                      ...prayerSessions.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.floatingCardDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.offWhiteBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.menu_book, color: AppTheme.coralPrimary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.theme,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppTheme.darkCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.scriptureRefs} • ${p.actualDurationMins} mins',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              if (p.isAnswered)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Answered',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPrayerDialog(BuildContext context) {
    final themeController = TextEditingController();
    final scriptureController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Prayer Reflection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: themeController,
              decoration: const InputDecoration(labelText: 'Prayer Theme / Intention'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scriptureController,
              decoration: const InputDecoration(labelText: 'Scripture Reference (e.g. Psalm 23:1)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              if (themeController.text.trim().isNotEmpty) {
                LocalDatabase.instance.addPrayerSession(
                  PrayerSession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    workspaceId: 'ws-personal',
                    theme: themeController.text.trim(),
                    scriptureRefs: scriptureController.text.trim(),
                    actualDurationMins: 30,
                    sessionDate: DateTime.now(),
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

  static String _monthShort(int month) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  static String _weekdayShort(int weekday) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}
