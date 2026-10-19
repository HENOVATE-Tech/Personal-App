import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedCategory = 'task';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 15)));

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _openAddAlarmDialog() {
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
                const Row(
                  children: [
                    Icon(Icons.alarm_add, color: AppTheme.coralPrimary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Schedule Ringing Alarm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Alarm Title / Commitment',
                    hintText: 'e.g. Executive Strategy Review',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    labelText: 'Details / Direct Action (optional)',
                    hintText: 'e.g. Review Bems Group cash flow doc',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category selector
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Alarm Category',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'task', child: Text('🎯 Task & Commitment')),
                    DropdownMenuItem(value: 'schedule', child: Text('📅 Calendar Schedule')),
                    DropdownMenuItem(value: 'study', child: Text('📖 Study & Research')),
                    DropdownMenuItem(value: 'prayer', child: Text('🙏 Prayer & Devotion')),
                    DropdownMenuItem(value: 'finance', child: Text('💰 Finance & Ledger')),
                    DropdownMenuItem(value: 'custom', child: Text('⏰ Custom Action')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Date & Time pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setModalState(() => _selectedTime = picked);
                          }
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    final alarmDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );

                    NotificationService.instance.scheduleAlarm(
                      title: title,
                      body: _bodyController.text.trim().isNotEmpty
                          ? _bodyController.text.trim()
                          : 'Scheduled alarm alert',
                      scheduledTime: alarmDateTime,
                      category: _selectedCategory,
                    );

                    _titleController.clear();
                    _bodyController.clear();
                    Navigator.of(ctx).pop();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ringing Alarm scheduled for ${AppDateUtils.formatTime(alarmDateTime)}'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  child: const Text(
                    'Set Ringing Alarm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
    final activeAlarms = NotificationService.instance.activeAlarms;

    return Scaffold(
      backgroundColor: AppTheme.creamCanvas,
      appBar: AppBar(
        title: const Text('Reminders & Ringing Alarms'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppTheme.coralPrimary),
            tooltip: 'Test Ringing Sound Now',
            onPressed: () {
              NotificationService.instance.testAlarmNow();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Test Alarm Triggered! Ringing audio active.'),
                  backgroundColor: AppTheme.darkCharcoal,
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.coralPrimary,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text('Set Alarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openAddAlarmDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetMesh,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ringing Audio Alarms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activeAlarms.length} Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Every task, schedule, routine, or study block can trigger a loud hardware alarm ringtone that persists until dismissed or snoozed.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Test Ringing Alarm Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.darkCharcoal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    NotificationService.instance.testAlarmNow();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Alarms Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Scheduled Alarms',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              Text(
                'Auto checks every 4s',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeAlarms.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                children: [
                  Icon(Icons.alarm_off, size: 48, color: AppTheme.textTertiary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No active alarms scheduled',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Schedule an alarm for your tasks, study sessions, or financial reviews to get loud audible alerts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...activeAlarms.map((alarm) {
              final isDue = DateTime.now().isAfter(alarm.scheduledTime);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softCardShadow,
                  border: isDue ? Border.all(color: AppTheme.coralPrimary, width: 1.5) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDue ? const Color(0xFFFFECE5) : const Color(0xFFF3F4F6),
                    child: Icon(
                      Icons.alarm,
                      color: isDue ? AppTheme.coralPrimary : AppTheme.darkCharcoal,
                    ),
                  ),
                  title: Text(
                    alarm.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(
                        alarm.body,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alarm.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppDateUtils.formatDateTime(alarm.scheduledTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                              color: isDue ? AppTheme.coralPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.textTertiary, size: 20),
                    onPressed: () {
                      NotificationService.instance.dismissActiveAlarm();
                      setState(() {});
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
