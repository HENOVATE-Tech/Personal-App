import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class WorkspacesOverviewScreen extends StatelessWidget {
  const WorkspacesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final bemsTasks = db.getTasks(workspaceId: AppConstants.workspaceBemsId);
        final henovateTasks = db.getTasks(workspaceId: AppConstants.workspaceHenovateId);
        final followUps = db.getFollowUps();

        // Calculate workload capacity in minutes
        final bemsMins = bemsTasks.where((t) => t.status != TaskStatus.completed).fold<int>(0, (s, t) => s + t.estimateMinutes);
        final henovateMins = henovateTasks.where((t) => t.status != TaskStatus.completed).fold<int>(0, (s, t) => s + t.estimateMinutes);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Professional Workspaces'),
              bottom: const TabBar(
                indicatorColor: AppTheme.sereneTeal,
                tabs: [
                  Tab(text: 'Bems Group (COO)'),
                  Tab(text: 'Henovate (Founder)'),
                  Tab(text: 'Follow-Ups'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. Bems Group Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFFECFDF5),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bems Group — Chief Operating Officer',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active Backlog: ${bemsTasks.length} tasks • Estimated workload: ${(bemsMins / 60).toStringAsFixed(1)} hrs',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...bemsTasks.map((t) => _buildTaskTile(context, t, db)),
                  ],
                ),

                // 2. Henovate Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFFF5F3FF),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Henovate — Founder & Architecture',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B21B6), fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active Backlog: ${henovateTasks.length} tasks • Estimated workload: ${(henovateMins / 60).toStringAsFixed(1)} hrs',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...henovateTasks.map((t) => _buildTaskTile(context, t, db)),
                  ],
                ),

                // 3. Delegated Follow-ups Tab (FR-WK-05)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      color: Color(0xFFF8FAFC),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Delegated Follow-up Tracker (FR-WK-05): Private personal ledger to track responses '
                          'and commitments without sending automated external emails or messages.',
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedGray),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (followUps.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No delegated follow-ups recorded yet.', style: TextStyle(color: AppTheme.mutedGray)),
                        ),
                      )
                    else
                      ...followUps.map((f) {
                        return Card(
                          child: ListTile(
                            title: Text(f.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Commitment: ${f.commitment}'),
                            trailing: Chip(
                              label: Text(f.status.toUpperCase(), style: const TextStyle(fontSize: 9)),
                              backgroundColor: f.status == 'received' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                            ),
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

  Widget _buildTaskTile(BuildContext context, Task t, LocalDatabase db) {
    final isDone = t.status == TaskStatus.completed;
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          activeColor: AppTheme.sereneTeal,
          onChanged: (_) => db.toggleTaskComplete(t.id),
        ),
        title: Text(
          t.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(t.nextAction.isNotEmpty ? 'Next: ${t.nextAction}' : '${t.estimateMinutes}m'),
        trailing: Chip(
          label: Text(t.importance.name.toUpperCase(), style: const TextStyle(fontSize: 9)),
        ),
      ),
    );
  }
}
