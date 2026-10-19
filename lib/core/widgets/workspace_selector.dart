import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../database/local_database.dart';
import '../database/schema_models.dart';

class WorkspaceSelector extends StatelessWidget {
  final String selectedWorkspaceId;
  final ValueChanged<String> onWorkspaceChanged;

  const WorkspaceSelector({
    super.key,
    required this.selectedWorkspaceId,
    required this.onWorkspaceChanged,
  });

  static const List<int> _colorOptions = [
    0xFF3B82F6, // Blue
    0xFF10B981, // Emerald
    0xFF8B5CF6, // Purple
    0xFFF59E0B, // Amber
    0xFFEF4444, // Crimson
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFF14B8A6, // Teal
  ];

  void _showAddOrEditWorkspaceDialog(BuildContext context, {Workspace? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.type ?? 'professional';
    int selectedColor = existing?.colorValue ?? _colorOptions.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(selectedColor).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.business_center, color: Color(selectedColor), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existing == null ? 'Create Workspace' : 'Edit Workspace',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Workspace Name',
                        hintText: 'e.g. Real Estate, Family, Ministry',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Workspace Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Personal'),
                          selected: selectedType == 'personal',
                          selectedColor: const Color(0xFFFFECE5),
                          onSelected: (_) => setDialogState(() => selectedType = 'personal'),
                        ),
                        ChoiceChip(
                          label: const Text('Professional'),
                          selected: selectedType == 'professional',
                          selectedColor: const Color(0xFFE0E7FF),
                          onSelected: (_) => setDialogState(() => selectedType = 'professional'),
                        ),
                        ChoiceChip(
                          label: const Text('Enterprise / Project'),
                          selected: selectedType == 'project',
                          selectedColor: const Color(0xFFD1FAE5),
                          onSelected: (_) => setDialogState(() => selectedType = 'project'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Brand Color', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((c) {
                        final isChosen = c == selectedColor;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isChosen
                                  ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isChosen
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null && !existing.isDefault)
                  TextButton(
                    onPressed: () {
                      LocalDatabase.instance.deleteWorkspace(existing.id);
                      if (selectedWorkspaceId == existing.id) {
                        onWorkspaceChanged('');
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Workspace "${existing.name}" deleted')),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final ws = Workspace(
                      id: existing?.id ?? 'ws-${const Uuid().v4().substring(0, 8)}',
                      name: name,
                      type: selectedType,
                      colorValue: selectedColor,
                      isDefault: existing?.isDefault ?? false,
                    );

                    LocalDatabase.instance.upsertWorkspace(ws);
                    onWorkspaceChanged(ws.id);
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final workspaces = LocalDatabase.instance.getWorkspaces();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // "All Workspaces" Chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All Workspaces'),
                  selected: selectedWorkspaceId.isEmpty,
                  onSelected: (_) => onWorkspaceChanged(''),
                  selectedColor: const Color(0xFFFFECE5),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedWorkspaceId.isEmpty ? AppTheme.coralPrimary : AppTheme.textSecondary,
                    fontWeight: selectedWorkspaceId.isEmpty ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selectedWorkspaceId.isEmpty ? AppTheme.coralPrimary : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ),
              ...workspaces.map((ws) {
                final isSelected = ws.id == selectedWorkspaceId;
                final chipColor = Color(ws.colorValue);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onLongPress: () => _showAddOrEditWorkspaceDialog(context, existing: ws),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        radius: 5,
                        backgroundColor: chipColor,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ws.name),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showAddOrEditWorkspaceDialog(context, existing: ws),
                              child: const Icon(Icons.edit_outlined, size: 13, color: AppTheme.coralPrimary),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => onWorkspaceChanged(ws.id),
                      selectedColor: const Color(0xFFFFECE5),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.coralPrimary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppTheme.coralPrimary : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // "+ Workspace" Action Chip
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: AppTheme.coralPrimary),
                label: const Text(
                  'Workspace',
                  style: TextStyle(
                    color: AppTheme.coralPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: const Color(0xFFFFECE5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFFCCBC)),
                ),
                onPressed: () => _showAddOrEditWorkspaceDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
