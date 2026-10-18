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
          appBar: AppBar(
            title: const Text('Spiritual Practice'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Gentle Continuity Card
              const Card(
                color: Color(0xFFEEF2FF),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.spa, color: Color(0xFF4F46E5), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gentle Continuity & Quiet Devotion',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Spiritual growth is a sustainable relationship, not a gamified points competition. '
                        'No streaks are broken here; return calmly at your next scheduled time.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF4338CA)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Devotion Slots
              const Text(
                'Configured Devotional Slots',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...routines.map((r) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      r.isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: r.isCompletedToday ? AppTheme.sereneTeal : AppTheme.mutedGray,
                    ),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Preferred time: ${r.preferredTimeLocal} (${r.targetDurationMins}m target)'),
                    trailing: OutlinedButton(
                      child: Text(r.isCompletedToday ? 'Done' : 'Mark Done'),
                      onPressed: () => db.toggleRoutineCompleted(r.id),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Fasting Schedule
              const Text(
                'Recurring Fasting Dates (This Month)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Weekly Mon/Fri + monthly 3-day weekend fast (deduplicated on Friday).',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedGray),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fastingSchedule.map((d) {
                  final isPast = d.isBefore(DateTime(now.year, now.month, now.day));
                  final isToday = AppDateUtils.isSameDay(d, now);

                  return Chip(
                    backgroundColor: isToday
                        ? const Color(0xFF2563EB)
                        : (isPast ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                    label: Text(
                      '${d.day} ${_monthShort(d.month)} (${_weekdayShort(d.weekday)})',
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? Colors.white : AppTheme.slateNavy,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              // Prayer Journal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prayer Journal Entries',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Entry'),
                    onPressed: () => _showAddPrayerDialog(context),
                  ),
                ],
              ),

              if (prayerSessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No prayer journal entries recorded yet. Tap "+ Add Entry" to record reflections.',
                        style: TextStyle(color: AppTheme.mutedGray),
                      ),
                    ),
                  ),
                )
              else
                ...prayerSessions.map((p) {
                  return Card(
                    child: ListTile(
                      title: Text(p.theme, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${p.scriptureRefs} • ${p.actualDurationMins} mins'),
                      trailing: p.isAnswered
                          ? const Chip(
                              label: Text('ANSWERED', style: TextStyle(fontSize: 9, color: Color(0xFF059669))),
                              backgroundColor: Color(0xFFD1FAE5),
                            )
                          : null,
                    ),
                  );
                }),
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
