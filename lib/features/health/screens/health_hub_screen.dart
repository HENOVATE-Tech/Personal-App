import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/sleep_validator.dart';

class HealthHubScreen extends StatelessWidget {
  const HealthHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final profile = db.userProfile;
        final sleepLogs = db.getSleepLogs();

        // Evaluate target rest window
        final bedParts = profile.bedtimeTarget.split(':');
        final wakeParts = profile.wakingTarget.split(':');
        final bedHour = int.tryParse(bedParts[0]) ?? 23;
        final bedMinute = int.tryParse(bedParts[1]) ?? 0;
        final wakeHour = int.tryParse(wakeParts[0]) ?? 6;
        final wakeMinute = int.tryParse(wakeParts[1]) ?? 0;

        final sleepEval = SleepValidator.evaluateWindow(
          bedHour: bedHour,
          bedMinute: bedMinute,
          wakeHour: wakeHour,
          wakeMinute: wakeMinute,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Health, Rest & Character'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Target Sleep Window Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Configured Sleep Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Chip(
                            label: Text('${sleepEval.hours.toStringAsFixed(1)} hrs window'),
                            backgroundColor: sleepEval.isInsufficient ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Bedtime: ${profile.bedtimeTarget} • Waking: ${profile.wakingTarget}', style: const TextStyle(fontSize: 13)),
                      if (sleepEval.isInsufficient && sleepEval.advisoryMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.softAmber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sleepEval.advisoryMessage!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recent Sleep Logs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Sleep Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Sleep'),
                    onPressed: () => _showLogSleepDialog(context),
                  ),
                ],
              ),
              if (sleepLogs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No sleep logs recorded yet. Tap "+ Log Sleep" to record sleep quality.', style: TextStyle(color: AppTheme.mutedGray)),
                    ),
                  ),
                )
              else
                ...sleepLogs.map((s) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bedtime, color: Color(0xFF6366F1)),
                      title: Text('${(s.actualSleepMins / 60).toStringAsFixed(1)} hours sleep'),
                      subtitle: Text('Score: ${s.wellbeingScore}/5 • ${s.notes ?? 'Peaceful rest'}'),
                    ),
                  );
                }),

              const SizedBox(height: 20),
              // Relationships & Character Notes
              const Text('Character & Personal Values (FR-CH-01)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Core Pillars of Daily Conduct:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 8),
                      Text('• Humility: Willingness to listen, receive feedback, and learn continuously.'),
                      SizedBox(height: 4),
                      Text('• Integrity: Complete congruence between private commitments and public word.'),
                      SizedBox(height: 4),
                      Text('• Punctuality & Respect: Honoring others’ time in Bems & Henovate engagements.'),
                      SizedBox(height: 4),
                      Text('• Self-Control & Calm: Responding deliberately rather than reacting impulsively.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogSleepDialog(BuildContext context) {
    final hoursCtrl = TextEditingController(text: '7.0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Last Night Sleep'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: hoursCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Actual sleep (Hours)')),
            const SizedBox(height: 10),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Wellbeing notes (Optional)')),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              final hours = double.tryParse(hoursCtrl.text) ?? 7.0;
              final now = DateTime.now();
              LocalDatabase.instance.addSleepLog(
                SleepLog(
                  id: now.millisecondsSinceEpoch.toString(),
                  bedtime: now.subtract(Duration(minutes: (hours * 60).toInt())),
                  wakeTime: now,
                  actualSleepMins: (hours * 60).toInt(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
