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

              // Time Blocks & Agenda Header
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
