import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/config/app_constants.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';
import 'package:personal_life_os/features/recovery/services/commitment_recovery_engine.dart';

void main() {
  group('Commitment Recovery Engine Tests (REC-101..110, FR-TS-07, BR-02)', () {
    late LocalDatabase db;
    late CommitmentRecoveryEngine engine;

    setUp(() {
      db = LocalDatabase.instance;
      db.wipeAllData();
      engine = CommitmentRecoveryEngine.instance;
    });

    test('REC-101: Overdue task by >= 3 days surfaces a recovery candidate', () {
      final now = DateTime.now();
      final overdueTask = Task(
        id: 'task-overdue-1',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Complete Deep Financial Analysis',
        scheduledDate: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 5)),
      );

      db.upsertTask(overdueTask);

      final candidates = engine.evaluateCommitments(referenceDate: now);
      expect(candidates.any((c) => c.sourceId == 'task-overdue-1'), isTrue);
    });

    test('REC-102: Anti-overwhelm cap — surfaces at most 3 recovery cards', () {
      final now = DateTime.now();
      for (int i = 0; i < 10; i++) {
        db.upsertTask(Task(
          id: 'task-overdue-$i',
          workspaceId: AppConstants.workspacePersonalId,
          title: 'Overdue task $i',
          scheduledDate: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 10)),
        ));
      }

      final cards = engine.evaluateCommitments(referenceDate: now);
      expect(cards.length, AppConstants.maxActiveRecoveryCards);
    });

    test('BR-02: Rescheduling preserves task identity and increments postponement count', () {
      final now = DateTime.now();
      final task = Task(
        id: 'task-keep-id',
        workspaceId: AppConstants.workspaceBemsId,
        title: 'Review Operations Matrix',
        postponementCount: 1,
        scheduledDate: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 10)),
      );

      db.upsertTask(task);

      final cards = engine.evaluateCommitments(referenceDate: now);
      final targetCard = cards.firstWhere((c) => c.sourceId == 'task-keep-id');

      final tomorrow = now.add(const Duration(days: 1));
      engine.applyRecoveryChoice(
        actionId: targetCard.id,
        choice: 'reschedule',
        sourceType: 'task',
        sourceId: 'task-keep-id',
        newScheduledDate: tomorrow,
      );

      final updatedTask = db.getTaskById('task-keep-id');
      expect(updatedTask, isNotNull);
      expect(updatedTask!.id, 'task-keep-id', reason: 'Task identity must not change on reschedule');
      expect(updatedTask.postponementCount, 2);
      expect(updatedTask.scheduledDate?.day, tomorrow.day);
    });

    test('FR-TS-07: "do_5_min" choice reduces task duration estimate to 5 minutes', () {
      final now = DateTime.now();
      final task = Task(
        id: 'task-5min',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Read Scripture exegesis',
        estimateMinutes: 60,
        postponementCount: 3,
        scheduledDate: now,
        createdAt: now.subtract(const Duration(days: 4)),
      );

      db.upsertTask(task);

      final cards = engine.evaluateCommitments(referenceDate: now);
      final targetCard = cards.firstWhere((c) => c.sourceId == 'task-5min');

      engine.applyRecoveryChoice(
        actionId: targetCard.id,
        choice: 'do_5_min',
        sourceType: 'task',
        sourceId: 'task-5min',
      );

      final updated = db.getTaskById('task-5min')!;
      expect(updated.estimateMinutes, 5);
    });
  });
}
