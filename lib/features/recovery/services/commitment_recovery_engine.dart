import 'package:uuid/uuid.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class CommitmentRecoveryEngine {
  static final CommitmentRecoveryEngine instance = CommitmentRecoveryEngine._internal();
  CommitmentRecoveryEngine._internal();

  final _uuid = const Uuid();

  /// Scans active tasks and habits to detect neglected commitments.
  /// Generates gentle recovery cards capped at AppConstants.maxActiveRecoveryCards (3)
  /// to eliminate cognitive and emotional overwhelm (FR-TS-07, Section 32).
  List<RecoveryAction> evaluateCommitments({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final db = LocalDatabase.instance;
    final List<RecoveryAction> candidates = [];

    // 1. Check Tasks: overdue by >= 3 days or postponed >= 3 times
    final tasks = db.getTasks().where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.archived);

    for (final task in tasks) {
      if (task.scheduledDate != null) {
        final daysOverdue = now.difference(task.scheduledDate!).inDays;
        if (daysOverdue >= AppConstants.defaultNeglectedThresholdDays) {
          candidates.add(RecoveryAction(
            id: _uuid.v4(),
            sourceType: 'task',
            sourceId: task.id,
            title: task.title,
            reason: 'Task has been pending for $daysOverdue days without physical next action.',
            createdAt: now,
          ));
        } else if (task.postponementCount >= 3) {
          candidates.add(RecoveryAction(
            id: _uuid.v4(),
            sourceType: 'task',
            sourceId: task.id,
            title: task.title,
            reason: 'Task postponed ${task.postponementCount} times. Consider breaking it down into a smaller step.',
            createdAt: now,
          ));
        }
      }
    }

    // 2. Check Uncompleted Chores
    final chores = db.getChores().where((c) => !c.isCompleted);
    for (final chore in chores) {
      if (chore.lastCompletedAt != null) {
        final daysSince = now.difference(chore.lastCompletedAt!).inDays;
        if (daysSince >= 14) {
          candidates.add(RecoveryAction(
            id: _uuid.v4(),
            sourceType: 'chore',
            sourceId: chore.id,
            title: chore.title,
            reason: 'Household chore not logged in $daysSince days. Would you like to do 10 minutes or delegate?',
            createdAt: now,
          ));
        }
      }
    }

    // Cap candidates to maxActiveRecoveryCards (3)
    return candidates.take(AppConstants.maxActiveRecoveryCards).toList();
  }

  /// Applies user's recovery choice to the target item without guilt or destructive loss.
  void applyRecoveryChoice({
    required String actionId,
    required String choice, // "do_5_min", "reschedule", "simplify", "pause", "cancel"
    required String sourceType,
    required String sourceId,
    DateTime? newScheduledDate,
  }) {
    final db = LocalDatabase.instance;

    if (sourceType == 'task') {
      final task = db.getTaskById(sourceId);
      if (task != null) {
        switch (choice) {
          case 'do_5_min':
            // Shrink estimate to 5 minutes so user can take a low-friction step
            db.upsertTask(task.copyWith(estimateMinutes: 5));
            break;
          case 'reschedule':
            db.upsertTask(task.copyWith(
              scheduledDate: newScheduledDate ?? DateTime.now().add(const Duration(days: 1)),
              postponementCount: task.postponementCount + 1,
            ));
            break;
          case 'simplify':
            db.upsertTask(task.copyWith(
              nextAction: 'First 5-minute micro action: Review notes',
              estimateMinutes: 10,
            ));
            break;
          case 'pause':
            db.upsertTask(task.copyWith(
              scheduledDate: DateTime.now().add(const Duration(days: 7)),
            ));
            break;
          case 'cancel':
            db.upsertTask(task.copyWith(status: TaskStatus.cancelled));
            break;
        }
      }
    }

    db.resolveRecoveryAction(actionId, choice);
  }
}
