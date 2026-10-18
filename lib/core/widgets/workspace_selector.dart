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
              child: ChoiceChip(
                avatar: CircleAvatar(
                  radius: 5,
                  backgroundColor: chipColor,
                ),
                label: Text(ws.name),
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
            );
          }),
        ],
      ),
    );
  }
}
