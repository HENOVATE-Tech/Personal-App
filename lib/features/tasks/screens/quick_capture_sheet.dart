import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key});

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  final _titleController = TextEditingController();
  final _nextActionController = TextEditingController();
  String _selectedWorkspaceId = AppConstants.workspacePersonalId;
  final TaskImportance _importance = TaskImportance.medium;
  final int _estimateMins = 30;
  bool _isTopPriority = false;

  final _uuid = const Uuid();

  @override
  void dispose() {
    _titleController.dispose();
    _nextActionController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      workspaceId: _selectedWorkspaceId,
      title: title,
      nextAction: _nextActionController.text.trim(),
      importance: _importance,
      estimateMinutes: _estimateMins,
      isTopPriority: _isTopPriority,
      scheduledDate: DateTime(now.year, now.month, now.day),
      createdAt: now,
    );

    LocalDatabase.instance.upsertTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = LocalDatabase.instance.getWorkspaces();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Capture',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'What commitment is on your mind?',
              hintText: 'e.g. Schedule team retro, review bank statement',
            ),
          ),
          const SizedBox(height: 12),

          // Next Physical Action
          TextField(
            controller: _nextActionController,
            decoration: const InputDecoration(
              labelText: 'Immediate next physical action',
              hintText: 'e.g. Open Figma link, draft message to Segun',
            ),
          ),
          const SizedBox(height: 12),

          // Workspace Picker
          DropdownButtonFormField<String>(
            value: _selectedWorkspaceId,
            decoration: const InputDecoration(labelText: 'Workspace'),
            items: workspaces.map((ws) {
              return DropdownMenuItem(
                value: ws.id,
                child: Text(ws.name),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedWorkspaceId = val);
            },
          ),
          const SizedBox(height: 12),

          // Top Priority Toggle
          SwitchListTile(
            title: const Text('Designate as Top Priority for Today'),
            value: _isTopPriority,
            activeColor: AppTheme.sereneTeal,
            onChanged: (val) => setState(() => _isTopPriority = val),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sereneTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
