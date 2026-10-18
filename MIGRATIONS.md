# DATABASE MIGRATIONS & SCHEMA EVOLUTION SPECIFICATION
## Personal Life OS (v2.0 Engineering Edition)

### 1. Migration Protocol
Database schema evolution is managed through deterministic, forward-versioned migration scripts implemented in `lib/core/database/schema_migrations.dart`.

#### Key Invariants:
1. **Pre-flight Checkpoint:** Before executing any migration step, `AppDatabase` performs an internal backup copy of `app_database.sqlite` to `app_database.sqlite.v{N}.bak`.
2. **Atomic Step Transactions:** Every schema alteration, column addition, or data transformation runs inside an isolated SQL transaction. If a failure occurs, SQLite rolls back to the savepoint and the previous schema version remains active (`BR-13`).
3. **No Destructive Re-creations:** Migrations never execute `DROP TABLE` on existing tables during normal upgrade cycles. Renamed or deprecated columns retain tombstones.

### 2. Versioned Migration Log

#### Version 1 (Baseline Initial Schema)
- `OwnerProfile`, `Workspace`, `Setting`, `Category`, `Tag`, `Attachment`, `AuditEvent`.
- `CalendarEvent`, `RecurrenceRule`, `OccurrenceException`, `ReminderIntent`, `TimeBlock`, `FocusSession`, `TimeLog`.
- `Task`, `TaskChecklistItem`, `TaskDependency`, `TaskActivity`, `TaskRescheduleHistory`, `Goal`, `Milestone`, `Project`, `FollowUp`.
- `PrayerSession`, `PrayerTopic`, `ScriptureStudy`, `ScriptureReference`, `MeditationEntry`, `FastPlan`, `SermonNote`, `SpiritualReflection`.
- `CareChecklist`, `Chore`, `HouseholdSupply`, `WardrobeItem`, `OutfitPlan`, `Completion`.
- `FinancialAccount`, `FinancialCategory`, `LedgerTransaction`, `LedgerMovement`, `Budget`, `Bill`, `Liability`, `SavingsGoal`, `Receipt`.
- `Book`, `ReadingSession`, `LearningPlan`, `Lesson`, `StudyNote`, `KnowledgeHighlight`.
- `SleepLog`, `WellbeingEntry`, `ExerciseEntry`, `Person`, `RelationshipReminder`, `CharacterReflection`.
- `JournalEntry`, `Review`, `MetricSnapshot`, `NotificationLog`, `BackupManifest`.

#### Version 2 (Planned Next Milestone)
- Adds optional foreign currency exchange rate cache for multi-currency travel scenarios.
- Adds recurring budget rollover history audit table.
- Indexes for full-text search token optimizations.
