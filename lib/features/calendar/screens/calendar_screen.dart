import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/recurrence_engine.dart';

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
          appBar: AppBar(
            title: const Text('Calendar & Planning'),
            actions: [
              IconButton(
                icon: const Icon(Icons.today, color: AppTheme.sereneTeal),
                tooltip: 'Jump to Today',
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Month Header with Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Calendar Days Row (Interactive Day Selector)
              SizedBox(
                height: 70,
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
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.sereneTeal
                              : (hasFast ? const Color(0xFFEFF6FF) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.sereneTeal
                                : (hasFast ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayShort(candidate.weekday),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white70 : AppTheme.mutedGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.slateNavy,
                              ),
                            ),
                            if (hasFast)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
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
              Card(
                color: isSelectedFasting ? const Color(0xFFEFF6FF) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isSelectedFasting ? Icons.water_drop : Icons.calendar_today,
                        color: isSelectedFasting ? const Color(0xFF2563EB) : AppTheme.sereneTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDateUtils.formatFullDate(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (isSelectedFasting)
                              const Text(
                                'Scheduled Fasting Day: Hydration & gentle continuity',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Blocks & Agenda
              const Text(
                'Scheduled Time Blocks & Devotions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...routines.map((r) {
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.sereneTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.schedule, color: AppTheme.sereneTeal, size: 20),
                    ),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Preferred start: ${r.preferredTimeLocal} • ${r.targetDurationMins} minutes'),
                    trailing: const Chip(
                      label: Text('RECURRING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
