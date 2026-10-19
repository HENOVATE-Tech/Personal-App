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
              const SizedBox(height: 6),

              // Tasks Scroll List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
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
                      )
                    : ListView(
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
                      ),
              ),
            ],
          ),
        );
      },
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
}
