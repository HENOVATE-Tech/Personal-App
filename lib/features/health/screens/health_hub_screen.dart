import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/sleep_validator.dart';

class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();
  double _todayWaterLiters = 2.0;

  final List<Map<String, dynamic>> _relationships = [
    {
      'id': 'rel-1',
      'name': 'Spouse & Family Sanctuary',
      'role': 'Immediate Family',
      'lastConnected': 'Today',
      'nextTouchpoint': 'Tonight (Dinner)',
      'notes': 'Quality undivided presence, evening devotion together.',
    },
    {
      'id': 'rel-2',
      'name': 'Spiritual Mentor / Pastor',
      'role': 'Spiritual Covering',
      'lastConnected': '3 days ago',
      'nextTouchpoint': 'Thursday',
      'notes': 'Discussion on prophetic season and spiritual stewardship.',
    },
    {
      'id': 'rel-3',
      'name': 'Bems Group Executive Leadership',
      'role': 'Board & C-Suite',
      'lastConnected': 'Yesterday',
      'nextTouchpoint': 'Tomorrow (Operations Sync)',
      'notes': 'Review Q4 expenditure audit and payroll continuity.',
    },
  ];

  final List<Map<String, dynamic>> _workouts = [
    {
      'id': 'w-1',
      'type': 'Strength & Gym',
      'duration': '45 mins',
      'time': '06:30 AM',
      'notes': 'Upper body push & core endurance',
    },
    {
      'id': 'w-2',
      'type': 'Brisk Walk & Meditation',
      'duration': '30 mins',
      'time': 'Yesterday',
      'notes': 'Outdoor walking prayer & mindset reset',
    },
  ];

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

  void _showLogSleepDialog(BuildContext context, LocalDatabase db) {
    TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);
    int quality = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final sleepMinutes = AppDateUtils.calculateDurationMinutes(
            startHour: sleepTime.hour,
            startMinute: sleepTime.minute,
            endHour: wakeTime.hour,
            endMinute: wakeTime.minute,
            forceCrossMidnight: true,
          );
          final hours = sleepMinutes / 60.0;

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
                  'Record Rest & Sleep Window',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.bedtime, size: 16, color: Color(0xFF6366F1)),
                        label: Text('Bed: ${sleepTime.format(context)}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: sleepTime);
                          if (picked != null) setModalState(() => sleepTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.wb_sunny, size: 16, color: Color(0xFFF59E0B)),
                        label: Text('Wake: ${wakeTime.format(context)}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: wakeTime);
                          if (picked != null) setModalState(() => wakeTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hours < 6.0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Rest Duration:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hours < 6.0 ? const Color(0xFF92400E) : const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        '${hours.toStringAsFixed(1)} Hours',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: hours < 6.0 ? const Color(0xFF92400E) : const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Sleep Quality:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 10),
                    ...List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= quality ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () => setModalState(() => quality = star),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final now = DateTime.now();
                    final bedDt = DateTime(now.year, now.month, now.day, sleepTime.hour, sleepTime.minute);
                    var wakeDt = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
                    if (wakeDt.isBefore(bedDt)) {
                      wakeDt = wakeDt.add(const Duration(days: 1));
                    }

                    final log = SleepLog(
                      id: 'sleep-${_uuid.v4().substring(0, 8)}',
                      bedtime: bedDt,
                      wakeTime: wakeDt,
                      actualSleepMins: sleepMinutes,
                      wellbeingScore: quality,
                      notes: 'Rest logged via Vitality Hub',
                    );

                    db.upsertSleepLog(log);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Log Rest Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddRelationshipDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              'Add Key Relationship Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contact / Person Name',
                hintText: 'e.g. Dr. Emmanuel, Executive Chairman',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              decoration: InputDecoration(
                labelText: 'Sphere / Relationship',
                hintText: 'e.g. Strategic Mentor, Key Partner, Family',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Touchpoint Intent & Notes',
                hintText: 'e.g. Monthly governance check-in, personal encouragement',
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                setState(() {
                  _relationships.add({
                    'id': 'rel-${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'role': roleCtrl.text.trim().isNotEmpty ? roleCtrl.text.trim() : 'Connection',
                    'lastConnected': 'Today',
                    'nextTouchpoint': 'Upcoming',
                    'notes': notesCtrl.text.trim(),
                  });
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Relationship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context) {
    final typeCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30 mins');
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              'Record Workout & Physical Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Activity / Workout Type',
                hintText: 'e.g. Strength Training, Morning Run, Swimming',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: InputDecoration(
                labelText: 'Duration',
                hintText: 'e.g. 45 mins',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notes & Intensity',
                hintText: 'e.g. High intensity, recovery stretch completed',
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
                final type = typeCtrl.text.trim();
                if (type.isEmpty) return;

                setState(() {
                  _workouts.insert(0, {
                    'id': 'w-${DateTime.now().millisecondsSinceEpoch}',
                    'type': type,
                    'duration': durationCtrl.text.trim(),
                    'time': 'Today',
                    'notes': notesCtrl.text.trim(),
                  });
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Log Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

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
                                  Icon(Icons.favorite, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Health & Well-being',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Vitality, Sleep & Relationships',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cross-midnight sleep validator, hydration logs & executive relationship connections',
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
                              Tab(text: 'Sleep Rest 😴'),
                              Tab(text: 'Hydration & Fitness 💧'),
                              Tab(text: 'Relationships 👥'),
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
                // 1. Sleep Rest Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Target Sleep Window Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Target Sleep Window', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkCharcoal)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sleepEval.isInsufficient ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${sleepEval.hours.toStringAsFixed(1)} hrs window',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: sleepEval.isInsufficient ? const Color(0xFFB45309) : const Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Bedtime: ${profile.bedtimeTarget} • Waking: ${profile.wakingTarget}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          if (sleepEval.isInsufficient && sleepEval.advisoryMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
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
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sleep Journal & Rest History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.darkCharcoal)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Log Sleep'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showLogSleepDialog(context, db),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (sleepLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.bedtime_outlined, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text('No sleep entries recorded yet. Tap "+ Log Sleep" to start tracking rest.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...sleepLogs.map((log) {
                        final hours = (log.actualSleepMins / 60.0).toStringAsFixed(1);
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
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.nights_stay, color: Color(0xFF4F46E5), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppDateUtils.formatTime(log.bedtime)} → ${AppDateUtils.formatTime(log.wakeTime)} ($hours hrs)',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          log.wellbeingScore.clamp(1, 5),
                                          (_) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppDateUtils.formatShortDate(log.wakeTime),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),

                // 2. Hydration & Fitness Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Water Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.local_drink, color: Color(0xFF0284C7), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Daily Hydration Tracker',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkCharcoal),
                                  ),
                                ],
                              ),
                              Text(
                                '${_todayWaterLiters.toStringAsFixed(1)}L / 3.0L',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_todayWaterLiters / 3.0).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: const Color(0xFF0284C7),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _todayWaterLiters += 0.25),
                                  child: const Text('+250ml Glass'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => setState(() => _todayWaterLiters += 0.5),
                                  child: const Text('+500ml Bottle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Workouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Workouts & Physical Activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.darkCharcoal)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Log Workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddWorkoutDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ..._workouts.map((w) {
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
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.fitness_center, color: Color(0xFF059669), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w['type'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${w['duration']} • ${w['time']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if ((w['notes'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(w['notes'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                // 3. Relationships Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Executive & Family CRM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.darkCharcoal)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddRelationshipDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ..._relationships.map((rel) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rel['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    rel['role'] as String,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.coralPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Last Connected: ${rel['lastConnected']} • Next: ${rel['nextTouchpoint']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if ((rel['notes'] as String).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  rel['notes'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
