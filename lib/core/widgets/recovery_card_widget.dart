import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../database/schema_models.dart';
import '../../features/recovery/services/commitment_recovery_engine.dart';

class RecoveryCardWidget extends StatelessWidget {
  final RecoveryAction action;

  const RecoveryCardWidget({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 1.5), // Gentle warm amber border
      ),
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.refresh_rounded, color: AppTheme.softAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gentle Recovery Opportunity',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.softAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF78350F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Do 5 mins now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: () {
                    CommitmentRecoveryEngine.instance.applyRecoveryChoice(
                      actionId: action.id,
                      choice: 'do_5_min',
                      sourceType: action.sourceType,
                      sourceId: action.sourceId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Target simplified to 5 minutes. You can do this!')),
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: () {
                    CommitmentRecoveryEngine.instance.applyRecoveryChoice(
                      actionId: action.id,
                      choice: 'reschedule',
                      sourceType: action.sourceType,
                      sourceId: action.sourceId,
                      newScheduledDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rescheduled to tomorrow with no penalty.')),
                    );
                  },
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: () {
                    CommitmentRecoveryEngine.instance.applyRecoveryChoice(
                      actionId: action.id,
                      choice: 'pause',
                      sourceType: action.sourceType,
                      sourceId: action.sourceId,
                    );
                  },
                  child: const Text('Pause 7 days'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
