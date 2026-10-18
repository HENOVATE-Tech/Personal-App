import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/config/app_constants.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';

void main() {
  group('Workspace Isolation & Data Partitioning (FR-WK-01, FR-WK-04, BR-16)', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.instance;
      db.wipeAllData();
    });

    test('FR-WK-01: Tasks strictly filter by workspace ID with zero leakage', () {
      final now = DateTime.now();

      final bemsTask = Task(
        id: 't-bems',
        workspaceId: AppConstants.workspaceBemsId,
        title: 'Bems COO Strategic Review',
        createdAt: now,
      );

      final henovateTask = Task(
        id: 't-henovate',
        workspaceId: AppConstants.workspaceHenovateId,
        title: 'Henovate Client Architecture',
        createdAt: now,
      );

      final personalTask = Task(
        id: 't-personal',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Sunday Laundry and Outfits',
        createdAt: now,
      );

      db.upsertTask(bemsTask);
      db.upsertTask(henovateTask);
      db.upsertTask(personalTask);

      // Verify Bems Group isolation
      final bemsList = db.getTasks(workspaceId: AppConstants.workspaceBemsId);
      expect(bemsList.any((t) => t.id == 't-bems'), isTrue);
      expect(bemsList.any((t) => t.id == 't-henovate'), isFalse);
      expect(bemsList.any((t) => t.id == 't-personal'), isFalse);

      // Verify Henovate isolation
      final henovateList = db.getTasks(workspaceId: AppConstants.workspaceHenovateId);
      expect(henovateList.any((t) => t.id == 't-henovate'), isTrue);
      expect(henovateList.any((t) => t.id == 't-bems'), isFalse);
      expect(henovateList.any((t) => t.id == 't-personal'), isFalse);

      // Verify Personal isolation
      final personalList = db.getTasks(workspaceId: AppConstants.workspacePersonalId);
      expect(personalList.any((t) => t.id == 't-personal'), isTrue);
      expect(personalList.any((t) => t.id == 't-bems'), isFalse);
      expect(personalList.any((t) => t.id == 't-henovate'), isFalse);
    });

    test('FR-WK-04: Empty workspace filter returns all records without omission', () {
      final all = db.getTasks(workspaceId: '');
      expect(all.length, greaterThanOrEqualTo(3));
    });
  });
}
