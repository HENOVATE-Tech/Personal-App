import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../database/local_database.dart';

class WorkspaceSelector extends StatelessWidget {
  final String selectedWorkspaceId;
  final ValueChanged<String> onWorkspaceChanged;

  const WorkspaceSelector({
    super.key,
    required this.selectedWorkspaceId,
    required this.onWorkspaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final workspaces = LocalDatabase.instance.getWorkspaces();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "All Workspaces" Chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All Workspaces'),
              selected: selectedWorkspaceId.isEmpty,
              onSelected: (_) => onWorkspaceChanged(''),
              selectedColor: AppTheme.sereneTeal.withOpacity(0.2),
              checkmarkColor: AppTheme.sereneTeal,
            ),
          ),
          ...workspaces.map((ws) {
            final isSelected = ws.id == selectedWorkspaceId;
            final chipColor = Color(ws.colorValue);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: CircleAvatar(
                  radius: 6,
                  backgroundColor: chipColor,
                ),
                label: Text(ws.name),
                selected: isSelected,
                onSelected: (_) => onWorkspaceChanged(ws.id),
                selectedColor: chipColor.withOpacity(0.18),
                checkmarkColor: chipColor,
              ),
            );
          }),
        ],
      ),
    );
  }
}
