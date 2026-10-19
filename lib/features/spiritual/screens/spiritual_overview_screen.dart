import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/recurrence_engine.dart';
import '../../bible/screens/bible_reader_screen.dart';
import '../../notes/screens/notes_workstation_screen.dart';

class SpiritualOverviewScreen extends StatefulWidget {
  const SpiritualOverviewScreen({super.key});

  @override
  State<SpiritualOverviewScreen> createState() => _SpiritualOverviewScreenState();
}

class _SpiritualOverviewScreenState extends State<SpiritualOverviewScreen> {
  final _uuid = const Uuid();
  String _prayerFilter = 'all'; // 'all', 'active', 'answered'
  bool _isFastActive = false;
  int _fastElapsedHours = 14;
  double _waterLiters = 1.75;

  void _showAddPrayerDialog(BuildContext context, [PrayerSession? existing]) {
    final themeController = TextEditingController(text: existing?.theme ?? '');
    final scriptureController = TextEditingController(text: existing?.scriptureRefs ?? '');
    final notesController = TextEditingController();
    int duration = existing?.actualDurationMins ?? 30;

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
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing == null ? 'Record Prayer Petition & Vision' : 'Edit Prayer Entry',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: themeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Prayer Theme / Intention / Prophetic Burden',
                    hintText: 'e.g. Divine Wisdom for Bems Expansion, Family Protection',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scriptureController,
                  decoration: InputDecoration(
                    labelText: 'Scripture Anchor Reference',
                    hintText: 'e.g. Isaiah 45:1-3, Psalm 91:1-4',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes / Prophetic Prompting (optional)',
                    hintText: 'e.g. Impressions received during early watch...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Duration Target:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('15m'),
                      selected: duration == 15,
                      onSelected: (_) => setModalState(() => duration = 15),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('30m'),
                      selected: duration == 30,
                      onSelected: (_) => setModalState(() => duration = 30),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('60m'),
                      selected: duration == 60,
                      onSelected: (_) => setModalState(() => duration = 60),
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
                    final theme = themeController.text.trim();
                    if (theme.isEmpty) return;

                    final session = PrayerSession(
                      id: existing?.id ?? 'pr-${_uuid.v4().substring(0, 8)}',
                      workspaceId: 'ws-personal',
                      theme: theme,
                      scriptureRefs: scriptureController.text.trim(),
                      actualDurationMins: duration,
                      sessionDate: existing?.sessionDate ?? DateTime.now(),
                      isAnswered: existing?.isAnswered ?? false,
                    );

                    LocalDatabase.instance.addPrayerSession(session);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: Text(
                    existing == null ? 'Save Prayer Entry' : 'Update Prayer Entry',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    TimeOfDay preferredTime = const TimeOfDay(hour: 6, minute: 0);
    int targetMins = 45;

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
                  'Add Spiritual Devotional Slot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Devotion Slot Title',
                    hintText: 'e.g. Midnight Watch, Word Study & Prophetic Decree',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text('Time: ${preferredTime.format(context)}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: preferredTime);
                          if (picked != null) setModalState(() => preferredTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: targetMins,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 Mins')),
                          DropdownMenuItem(value: 30, child: Text('30 Mins')),
                          DropdownMenuItem(value: 45, child: Text('45 Mins')),
                          DropdownMenuItem(value: 60, child: Text('60 Mins')),
                          DropdownMenuItem(value: 120, child: Text('2 Hours')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => targetMins = val);
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

                    final formattedTime =
                        '${preferredTime.hour.toString().padLeft(2, '0')}:${preferredTime.minute.toString().padLeft(2, '0')}';

                    final routine = RoutineTemplate(
                      id: 'rt-${_uuid.v4().substring(0, 8)}',
                      title: title,
                      preferredTimeLocal: formattedTime,
                      targetDurationMins: targetMins,
                      category: 'Spiritual',
                    );

                    LocalDatabase.instance.upsertRoutineTemplate(routine);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
        final routines = db.getRoutineTemplates().where((r) => r.category == 'Spiritual').toList();
        final prayerSessions = db.getPrayerSessions();
        final now = DateTime.now();
        final fastingSchedule = RecurrenceEngine.getFastingScheduleForMonth(year: now.year, month: now.month);
        final bool isTodayFasting = fastingSchedule.any((d) => AppDateUtils.isSameDay(d, now));

        List<PrayerSession> displayedPrayers = prayerSessions;
        if (_prayerFilter == 'active') displayedPrayers = prayerSessions.where((p) => !p.isAnswered).toList();
        if (_prayerFilter == 'answered') displayedPrayers = prayerSessions.where((p) => p.isAnswered).toList();

        return Scaffold(
          backgroundColor: AppTheme.creamCanvas,
          body: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top + 16 : 56,
                    20,
                    24,
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
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.auto_stories, color: Colors.white, size: 16),
                                label: const Text('Read Bible', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const BibleReaderScreen()),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.note_alt_outlined, color: Colors.white, size: 16),
                                label: const Text('Revelation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotesWorkstationScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Spiritual Life & Sanctuary',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gentle continuity, prayer journal, 3-day fasting engine & prophetic revelations',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. FASTING COMMAND CENTER CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isTodayFasting ? const Color(0xFFDBEAFE) : const Color(0xFFFFECE5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isTodayFasting ? Icons.water_drop : Icons.spa,
                                      color: isTodayFasting ? const Color(0xFF2563EB) : AppTheme.coralPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isTodayFasting ? 'Fast Day Active 🕊️' : 'Fasting Engine',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkCharcoal),
                                      ),
                                      Text(
                                        isTodayFasting
                                            ? '$_fastElapsedHours hrs into fast • Water: ${_waterLiters.toStringAsFixed(1)}L logged'
                                            : 'Weekly Mon/Fri & 3-day monthly weekend fast',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isFastActive || isTodayFasting,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (val) {
                                  setState(() => _isFastActive = val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val ? 'Fasting period active. Hydration tracked.' : 'Fast logged.'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.local_drink, size: 16, color: Color(0xFF0284C7)),
                                  label: Text('+250ml Water (${_waterLiters.toStringAsFixed(1)}L)', style: const TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    setState(() => _waterLiters += 0.25);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.timer, size: 16),
                                  label: const Text('+1 hr Elapsed', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    setState(() => _fastElapsedHours += 1);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. DEVOTIONAL SLOTS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Devotional Slots & Watches',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16, color: AppTheme.coralPrimary),
                          label: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.coralPrimary)),
                          onPressed: () => _showAddRoutineDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                                child: r.isCompletedToday ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
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
                            IconButton(
                              icon: const Icon(Icons.alarm_add, color: AppTheme.coralPrimary, size: 20),
                              tooltip: 'Set Alarm for this prayer slot',
                              onPressed: () {
                                final parts = r.preferredTimeLocal.split(':');
                                final hour = int.tryParse(parts[0]) ?? 6;
                                final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                                final alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

                                NotificationService.instance.scheduleAlarm(
                                  title: '🙏 Prayer Slot: ${r.title}',
                                  body: 'Scheduled devotion commitment (${r.targetDurationMins}m)',
                                  scheduledTime: alarmTime.isAfter(DateTime.now()) ? alarmTime : alarmTime.add(const Duration(days: 1)),
                                  category: 'prayer',
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Alarm scheduled for ${r.title} at ${r.preferredTimeLocal}! ⏰'),
                                    backgroundColor: AppTheme.darkCharcoal,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                              tooltip: 'Delete Slot',
                              onPressed: () => db.deleteRoutineTemplate(r.id),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // 3. FASTING SCHEDULE THIS MONTH
                    const Text(
                      'Fasting Schedule (This Month)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deduplicated weekly Mon/Fri and 3-day monthly weekend sequence.',
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
                            color: isToday ? AppTheme.darkCharcoal : (isPast ? Colors.grey.shade100 : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isToday ? AppTheme.darkCharcoal : Colors.black.withOpacity(0.06)),
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

                    // 4. PRAYER JOURNAL PRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prayer Journal & Petitions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Petition'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddPrayerDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter chips for prayers
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('All (${prayerSessions.length})'),
                          selected: _prayerFilter == 'all',
                          selectedColor: AppTheme.darkCharcoal,
                          labelStyle: TextStyle(
                            color: _prayerFilter == 'all' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _prayerFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Active Requests (${prayerSessions.where((p) => !p.isAnswered).length})'),
                          selected: _prayerFilter == 'active',
                          selectedColor: AppTheme.darkCharcoal,
                          labelStyle: TextStyle(
                            color: _prayerFilter == 'active' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _prayerFilter = 'active'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Answered 🎉 (${prayerSessions.where((p) => p.isAnswered).length})'),
                          selected: _prayerFilter == 'answered',
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            color: _prayerFilter == 'answered' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _prayerFilter = 'answered'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (displayedPrayers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.menu_book, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text('No prayer entries matching this filter.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...displayedPrayers.map((p) {
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
                                  color: p.isAnswered ? const Color(0xFFD1FAE5) : AppTheme.offWhiteBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  p.isAnswered ? Icons.check_circle : Icons.bookmark_border,
                                  color: p.isAnswered ? const Color(0xFF059669) : AppTheme.coralPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showAddPrayerDialog(context, p),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.theme,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppTheme.darkCharcoal,
                                          decoration: p.isAnswered ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.scriptureRefs.isNotEmpty ? p.scriptureRefs : "General petition"} • ${p.actualDurationMins} mins',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: p.isAnswered ? const Color(0xFFF3F4F6) : const Color(0xFFD1FAE5),
                                  foregroundColor: p.isAnswered ? Colors.grey : const Color(0xFF065F46),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  db.addPrayerSession(
                                    PrayerSession(
                                      id: p.id,
                                      workspaceId: p.workspaceId,
                                      theme: p.theme,
                                      scriptureRefs: p.scriptureRefs,
                                      actualDurationMins: p.actualDurationMins,
                                      sessionDate: p.sessionDate,
                                      isAnswered: !p.isAnswered,
                                    ),
                                  );
                                },
                                child: Text(
                                  p.isAnswered ? 'Re-open' : 'Answered! 🎉',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                                tooltip: 'Delete Petition',
                                onPressed: () => db.deletePrayerSession(p.id),
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

  static String _monthShort(int month) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  static String _weekdayShort(int weekday) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}
