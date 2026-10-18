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
          appBar: AppBar(
            title: const Text('Tasks & Commitments'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.sereneTeal),
                tooltip: 'Quick Capture',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const QuickCaptureSheet(),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Workspace Selector Filter
              WorkspaceSelector(
                selectedWorkspaceId: _selectedWorkspaceId,
                onWorkspaceChanged: (id) => setState(() => _selectedWorkspaceId = id),
              ),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Active'),
                      selected: _selectedStatus == null,
                      onSelected: (_) => setState(() => _selectedStatus = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: _selectedStatus == TaskStatus.completed,
                      onSelected: (_) => setState(() => _selectedStatus = TaskStatus.completed),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Task List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.task_alt, size: 48, color: AppTheme.mutedGray),
                            const SizedBox(height: 12),
                            const Text(
                              'No tasks found for this workspace.',
                              style: TextStyle(color: AppTheme.mutedGray),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Capture Task'),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => const QuickCaptureSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
                          if (pendingTasks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Pending Actions (${pendingTasks.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            ...pendingTasks.map((t) => _buildTaskRow(context, t, db)),
                          ],
                          if (completedTasks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                'Completed (${completedTasks.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.mutedGray),
                              ),
                            ),
                            ...completedTasks.map((t) => _buildTaskRow(context, t, db)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.sereneTeal,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const QuickCaptureSheet(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskRow(BuildContext context, Task task, LocalDatabase db) {
    final isDone = task.status == TaskStatus.completed;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          activeColor: AppTheme.sereneTeal,
          onChanged: (_) => db.toggleTaskComplete(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.nextAction.isNotEmpty)
              Text(
                'Next: ${task.nextAction}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            Text(
              'Est: ${task.estimateMinutes}m • ${task.workspaceId.replaceFirst('ws-', '').toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedGray),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.mutedGray),
          onPressed: () => db.deleteTask(task.id),
        ),
      ),
    );
  }
}
