import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/recurrence_engine.dart';
import '../../tasks/screens/quick_capture_sheet.dart';
import '../../reminders/screens/reminders_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final fastingSchedule = RecurrenceEngine.getFastingScheduleForMonth(
          year: _selectedDate.year,
          month: _selectedDate.month,
        );

        final bool isSelectedFasting = fastingSchedule.any((d) => AppDateUtils.isSameDay(d, _selectedDate));
        final routines = db.getRoutineTemplates();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Calendar & Planning'),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.today, color: AppTheme.coralPrimary, size: 18),
                label: const Text('Today', style: TextStyle(color: AppTheme.coralPrimary, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 110 + MediaQuery.of(context).padding.bottom),
            children: [
              // Month Selector Header Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softCardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                        });
                      },
                    ),
                    Text(
                      '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Calendar Days Horizontal Carousel
              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day,
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    final candidate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                    final isSelected = candidate.day == _selectedDate.day;
                    final hasFast = fastingSchedule.any((d) => d.day == dayNumber);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = candidate),
                      child: Container(
                        width: 54,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.sunsetMesh : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected ? AppTheme.heroFloatShadow : AppTheme.softCardShadow,
                          border: Border.all(
                            color: isSelected ? Colors.transparent : (hasFast ? const Color(0xFFBFDBFE) : const Color(0xFFF3F4F6)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayShort(candidate.weekday),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            if (hasFast)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Selected Date Summary Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelectedFasting ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softCardShadow,
                  border: isSelectedFasting ? Border.all(color: const Color(0xFFBFDBFE)) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isSelectedFasting ? const Color(0xFFDBEAFE) : const Color(0xFFFFECE5),
                      child: Icon(
                        isSelectedFasting ? Icons.water_drop : Icons.calendar_today,
                        color: isSelectedFasting ? const Color(0xFF2563EB) : AppTheme.coralPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.formatFullDate(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelectedFasting
                                ? 'Scheduled Fast Day • Hydration & gentle continuity'
                                : 'Standard Schedule',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelectedFasting ? const Color(0xFF1E40AF) : AppTheme.textSecondary,
                              fontWeight: isSelectedFasting ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_task, size: 16),
                      label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkCharcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const QuickCaptureSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.alarm_add, size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Set Alarm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RemindersScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 1: Scheduled Tasks for this date
              Builder(
                builder: (context) {
                  final tasksForDay = db.getTasks().where((t) {
                    if (t.scheduledDate == null) return false;
                    return AppDateUtils.isSameDay(t.scheduledDate!, _selectedDate);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Scheduled Tasks',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${tasksForDay.length} Planned',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (tasksForDay.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          child: const Center(
                            child: Text(
                              'No tasks scheduled for this date.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...tasksForDay.map((task) {
                          final isCompleted = task.status == TaskStatus.completed;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                activeColor: AppTheme.coralPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (val) {
                                  db.toggleTaskComplete(task.id);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: task.nextAction.isNotEmpty
                                  ? Text(task.nextAction, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: task.isTopPriority ? const Color(0xFFFFECE5) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.isTopPriority ? 'TOP PRIORITY' : '${task.estimateMinutes}m',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: task.isTopPriority ? AppTheme.coralPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // SECTION 2: Ringing Alarms for this date
              Builder(
                builder: (context) {
                  final alarmsForDay = NotificationService.instance.activeAlarms.where((a) {
                    return AppDateUtils.isSameDay(a.scheduledTime, _selectedDate);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ringing Alarms & Audio Alerts',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${alarmsForDay.length} Alarms',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (alarmsForDay.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          child: const Center(
                            child: Text(
                              'No ringing alarms set for this date.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...alarmsForDay.map((alarm) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFECE5),
                                child: Icon(Icons.alarm, color: AppTheme.coralPrimary, size: 20),
                              ),
                              title: Text(alarm.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                '${AppDateUtils.formatTime(alarm.scheduledTime)} • ${alarm.body}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // SECTION 3: Financial Cash Movement for this date
              Builder(
                builder: (context) {
                  final txs = db.getLedgerTransactions().where((tx) {
                    return AppDateUtils.isSameDay(tx.effectiveAt, _selectedDate);
                  }).toList();

                  int inflow = 0;
                  int outflow = 0;
                  final movements = db.getLedgerMovements();
                  for (final tx in txs) {
                    final txMovements = movements.where((m) => m.transactionId == tx.id).toList();
                    for (final m in txMovements) {
                      if (m.amountKobo > 0) {
                        inflow += m.amountKobo;
                      } else {
                        outflow += m.amountKobo.abs();
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Financial Cash Movement',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                          Text(
                            MoneyFormatter.formatKobo(inflow - outflow),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: (inflow - outflow) >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (txs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          child: const Center(
                            child: Text(
                              'No transactions recorded on this date.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...txs.map((tx) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx.type == TransactionType.income
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                child: Icon(
                                  tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: tx.type == TransactionType.income ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  size: 18,
                                ),
                              ),
                              title: Text(tx.memo.isNotEmpty ? tx.memo : 'Ledger Movement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(AppDateUtils.formatTime(tx.effectiveAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              trailing: Text(
                                tx.type.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // SECTION 4: Time Blocks & Spiritual Slots Header
              const Text(
                'Time Blocks & Spiritual Slots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              ...routines.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.schedule, color: AppTheme.coralPrimary, size: 20),
                    ),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      'Preferred: ${r.preferredTimeLocal} • ${r.targetDurationMins} minutes',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('RECURRING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
