import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/widgets/workspace_selector.dart';
import 'quick_capture_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedWorkspaceId = '';
  TaskStatus? _selectedStatus;
  bool _isCalendarView = false;
  DateTime _calendarDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        var tasks = db.getTasks(workspaceId: _selectedWorkspaceId);

        if (_selectedStatus != null) {
          tasks = tasks.where((t) => t.status == _selectedStatus).toList();
        }

        final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
        final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

        final scheduledDayTasks = tasks.where((t) {
          if (t.scheduledDate == null) return false;
          return t.scheduledDate!.year == _calendarDate.year &&
              t.scheduledDate!.month == _calendarDate.month &&
              t.scheduledDate!.day == _calendarDate.day;
        }).toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Tasks & Commitments'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.coralPrimary, size: 28),
                tooltip: 'Quick Capture',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const QuickCaptureSheet(),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Workspace Selector
              WorkspaceSelector(
                selectedWorkspaceId: _selectedWorkspaceId,
                onWorkspaceChanged: (id) => setState(() => _selectedWorkspaceId = id),
              ),

              // View Mode Selector (List vs Calendar Schedule)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('List View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.format_list_bulleted, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Calendar Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.calendar_month, size: 16),
                          ),
                        ],
                        selected: {_isCalendarView},
                        onSelectionChanged: (set) => setState(() => _isCalendarView = set.first),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isCalendarView) ...[
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Active Tasks'),
                        selected: _selectedStatus == null,
                        onSelected: (_) => setState(() => _selectedStatus = null),
                        selectedColor: const Color(0xFFFFECE5),
                        checkmarkColor: AppTheme.coralPrimary,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Completed'),
                        selected: _selectedStatus == TaskStatus.completed,
                        onSelected: (_) => setState(() => _selectedStatus = TaskStatus.completed),
                        selectedColor: const Color(0xFFFFECE5),
                        checkmarkColor: AppTheme.coralPrimary,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Calendar Day Selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () {
                              setState(() {
                                _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1, 1);
                              });
                            },
                          ),
                          Text(
                            '${_getMonthName(_calendarDate.month)} ${_calendarDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () {
                              setState(() {
                                _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1, 1);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 65,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: DateTime(_calendarDate.year, _calendarDate.month + 1, 0).day,
                          itemBuilder: (context, index) {
                            final day = index + 1;
                            final current = DateTime(_calendarDate.year, _calendarDate.month, day);
                            final isSel = current.day == _calendarDate.day &&
                                current.month == _calendarDate.month &&
                                current.year == _calendarDate.year;

                            final hasTask = tasks.any((t) =>
                                t.scheduledDate != null &&
                                t.scheduledDate!.day == day &&
                                t.scheduledDate!.month == _calendarDate.month &&
                                t.scheduledDate!.year == _calendarDate.year);

                            return GestureDetector(
                              onTap: () => setState(() => _calendarDate = current),
                              child: Container(
                                width: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.coralPrimary : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? AppTheme.coralPrimary : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getWeekdayLetter(current.weekday),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white70 : Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSel ? Colors.white : AppTheme.darkCharcoal,
                                      ),
                                    ),
                                    if (hasTask)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: isSel ? Colors.white : AppTheme.coralPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // Tasks Scroll List
              Expanded(
                child: _buildTaskListContent(
                  context,
                  db: db,
                  isCalendarView: _isCalendarView,
                  calendarDate: _calendarDate,
                  scheduledDayTasks: scheduledDayTasks,
                  tasks: tasks,
                  pendingTasks: pendingTasks,
                  completedTasks: completedTasks,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskListContent(
    BuildContext context, {
    required LocalDatabase db,
    required bool isCalendarView,
    required DateTime calendarDate,
    required List<Task> scheduledDayTasks,
    required List<Task> tasks,
    required List<Task> pendingTasks,
    required List<Task> completedTasks,
  }) {
    if (isCalendarView) {
      if (scheduledDayTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available, size: 44, color: AppTheme.textTertiary),
              const SizedBox(height: 10),
              Text(
                'No tasks scheduled for ${calendarDate.day} ${_getMonthName(calendarDate.month)}.',
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('Schedule Task for ${calendarDate.day} ${_getMonthName(calendarDate.month)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coralPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const QuickCaptureSheet(),
                  );
                },
              ),
            ],
          ),
        );
      }
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 110 + MediaQuery.of(context).padding.bottom),
        children: scheduledDayTasks.map((task) => _buildTaskCard(context, task, db)).toList(),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 12),
            const Text(
              'No tasks found for this workspace.',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Capture Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const QuickCaptureSheet(),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 110 + MediaQuery.of(context).padding.bottom),
      children: [
        if (pendingTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Pending Actions (${pendingTasks.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),
          ...pendingTasks.map((t) => _buildTaskCard(context, t, db)),
        ],
        if (completedTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Text(
              'Completed (${completedTasks.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
          ...completedTasks.map((t) => _buildTaskCard(context, t, db)),
        ],
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, LocalDatabase db) {
    final isDone = task.status == TaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Checkbox(
          value: isDone,
          activeColor: AppTheme.coralPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (_) => db.toggleTaskComplete(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.nextAction.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Next: ${task.nextAction}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelPeach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.workspaceId.replaceFirst('ws-', '').toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.pastelPeachText),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${task.estimateMinutes}m est.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textTertiary),
          onPressed: () => db.deleteTask(task.id),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _getWeekdayLetter(int weekday) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (weekday >= 1 && weekday <= 7) return letters[weekday - 1];
    return '';
  }
}
