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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
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
              const Text(
                'Capture Commitment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppTheme.textTertiary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'What commitment is on your mind?',
              hintText: 'e.g. Prepare Friday operations slides',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Next Physical Action
          TextField(
            controller: _nextActionController,
            decoration: InputDecoration(
              labelText: 'Immediate next physical action',
              hintText: 'e.g. Open Google Drive folder',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Workspace Picker
          DropdownButtonFormField<String>(
            value: _selectedWorkspaceId,
            decoration: InputDecoration(
              labelText: 'Workspace Partition',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            items: workspaces.map((ws) {
              return DropdownMenuItem(
                value: ws.id,
                child: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedWorkspaceId = val);
            },
          ),
          const SizedBox(height: 12),

          // Top Priority Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Top Priority for Today', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            value: _isTopPriority,
            activeColor: AppTheme.coralPrimary,
            onChanged: (val) => setState(() => _isTopPriority = val),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkCharcoal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _save,
            child: const Text('Save Commitment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
