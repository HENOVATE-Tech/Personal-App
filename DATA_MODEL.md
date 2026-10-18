# DATA MODEL SPECIFICATION
## Personal Life OS (v2.0 Engineering Edition)

### 1. Relational Entities Baseline
Every entity uses standard UUIDv4 primary keys and includes UTC timestamps (`created_at_utc`, `updated_at_utc`, `deleted_at_utc`) and a monotonically increasing `revision` integer for migration safety and eventual multi-device sync.

```
                           +----------------------+
                           |     OwnerProfile     |
                           +----------------------+
                                      |
                                      v
+------------------+       +----------------------+       +----------------------+
|    Workspace     |<----->|      AppDatabase     |<----->|       Setting        |
+------------------+       +----------------------+       +----------------------+
  |           |                       |                              |
  v           v                       v                              v
+-------+   +-----------+   +-------------------+          +-------------------+
| Task  |   |  Project  |   | LedgerTransaction |          |  RoutineTemplate  |
+-------+   +-----------+   +-------------------+          +-------------------+
  |           |                       |                              |
  v           v                       v                              v
+-------+   +-----------+   +-------------------+          +-------------------+
|Check- |   | Milestone |   |  LedgerMovement   |          |  RecurrenceRule   |
| list  |   +-----------+   +-------------------+          +-------------------+
+-------+                             |                              |
                                      v                              v
                            +-------------------+          +-------------------+
                            | FinancialAccount  |          |    Completion     |
                            +-------------------+          +-------------------+
```

### 2. Entity Catalog

| Entity | Primary Key | Required Attributes | Foreign Keys | Constraints |
|---|---|---|---|---|
| `UserProfile` | `id: UUID` | `locale`, `timezone`, `currency`, `week_start`, `bedtime_target`, `waking_target` | None | Exactly 1 active profile |
| `Workspace` | `id: UUID` | `name`, `type`, `color_hex`, `is_default`, `archived` | None | Unique name |
| `Setting` | `key: String` | `value_json`, `is_encrypted` | None | Unique key |
| `RoutineTemplate` | `id: UUID` | `title`, `category`, `preferred_time_local`, `target_duration_mins`, `min_duration_mins` | `owner_id` | `target_duration_mins > 0` |
| `RecurrenceRule` | `id: UUID` | `frequency`, `interval`, `weekdays_mask`, `month_policy`, `until_utc`, `count` | `routine_id` | Compatible frequency attributes |
| `OccurrenceException` | `id: UUID` | `original_start_utc`, `override_start_utc`, `is_cancelled` | `routine_id` | Unique `(routine_id, original_start_utc)` |
| `Completion` | `id: UUID` | `occurrence_key`, `state`, `actual_duration_mins`, `notes` | `routine_id` | Unique `(routine_id, occurrence_key)` |
| `CalendarEvent` | `id: UUID` | `title`, `start_utc`, `end_utc`, `is_all_day`, `category` | `workspace_id`, `recurrence_id` | Cross-midnight duration > 0 |
| `TimeBlock` | `id: UUID` | `start_utc`, `end_utc`, `category`, `actual_logged_mins` | `workspace_id`, `linked_event_id` | End > Start |
| `Task` | `id: UUID` | `title`, `next_action`, `status`, `importance`, `due_utc`, `scheduled_utc`, `estimate_mins` | `workspace_id`, `project_id` | Title not empty; Enum status |
| `TaskChecklistItem`| `id: UUID` | `title`, `is_completed`, `position` | `task_id` | Position >= 0 |
| `TaskDependency` | `id: UUID` | `task_id`, `depends_on_task_id` | `task_id`, `task_id` | No self-dependency, no cycles |
| `TaskActivity` | `id: UUID` | `action_type`, `old_value`, `new_value`, `reason` | `task_id` | Immutable audit line |
| `Project` | `id: UUID` | `name`, `objective`, `status`, `start_date`, `target_date` | `workspace_id` | Unique name in workspace |
| `Milestone` | `id: UUID` | `title`, `due_date`, `status`, `position` | `project_id` | Position >= 0 |
| `FollowUp` | `id: UUID` | `person_name`, `commitment`, `requested_date`, `expected_date`, `status` | `workspace_id` | Private local ledger |
| `PrayerSession` | `id: UUID` | `theme`, `scripture_refs`, `actual_duration_mins`, `notes_encrypted` | `workspace_id` | Masked in notifications |
| `ScriptureStudy` | `id: UUID` | `book`, `chapter`, `passage`, `observations`, `application` | None | Offline reference planner |
| `FastPlan` | `id: UUID` | `title`, `start_local`, `end_local`, `mode`, `safety_notes` | `recurrence_id` | Friday deduplication rule |
| `CareChecklist` | `id: UUID` | `title`, `period`, `category`, `position` | None | Daily / weekly hygiene |
| `Chore` | `id: UUID` | `title`, `frequency`, `last_completed_utc`, `estimated_mins` | `workspace_id` | Repeatable household tasks |
| `WardrobeItem` | `id: UUID` | `name`, `category`, `color`, `laundry_status` | None | Wardrobe catalog |
| `OutfitPlan` | `id: UUID` | `calendar_date`, `outfit_description`, `items_csv` | None | Unique `calendar_date` |
| `FinancialAccount` | `id: UUID` | `name`, `account_type`, `currency`, `opening_balance_minor`, `archived` | None | Minor units (kobo) |
| `FinancialCategory`| `id: UUID` | `name`, `type`, `icon_name`, `color_hex` | None | Income / Expense category |
| `LedgerTransaction`| `id: UUID` | `type`, `status`, `effective_at_utc`, `memo`, `original_transaction_id` | None | Balanced double-entry |
| `LedgerMovement` | `id: UUID` | `account_id`, `category_id`, `amount_minor`, `currency` | `transaction_id` | `Sum(amount_minor) == 0` |
| `Budget` | `id: UUID` | `period_month_year`, `allocated_minor`, `rollover_policy` | `category_id` | Unique `(period, category_id)` |
| `Bill` | `id: UUID` | `payee`, `amount_minor`, `due_day`, `is_paid` | `category_id`, `account_id` | Never counts as spent until paid |
| `Liability` | `id: UUID` | `creditor_name`, `principal_minor`, `remaining_minor`, `due_date`| None | Debt tracking |
| `SavingsGoal` | `id: UUID` | `title`, `target_minor`, `target_date`, `accumulated_minor` | `linked_account_id` | Savings transfers != expenses |
| `Book` | `id: UUID` | `title`, `author`, `format`, `total_pages`, `current_page`, `status` | None | `current_page <= total_pages` |
| `ReadingSession` | `id: UUID` | `pages_read`, `duration_mins`, `notes` | `book_id` | Positive duration |
| `SleepLog` | `id: UUID` | `bedtime_utc`, `wake_utc`, `actual_sleep_mins`, `wellbeing_score` | None | Caution if window <= 5 hours |
| `JournalEntry` | `id: UUID` | `title`, `body_encrypted`, `entry_date`, `visibility` | `workspace_id` | AES-256-GCM encrypted |
| `RecoveryAction` | `id: UUID` | `source_type`, `source_id`, `action_chosen`, `reason` | None | Max 3 active recovery cards |
| `BackupManifest` | `id: UUID` | `schema_version`, `app_version`, `sha256_checksum`, `record_counts_json` | None | Atomic restore verification |

### 3. Financial Invariant Proof
Every transaction in `LedgerTransaction` must satisfy:
$$\sum_{i=1}^n \text{LedgerMovement}_i.\text{amount\_minor} = 0$$

For example, when recording a ₦5,000 grocery expense paid from a Guaranty Trust Bank account:
1. `Movement 1`: `account_id = GTB_ID`, `amount_minor = -500000` (decreases asset by ₦5,000.00).
2. `Movement 2`: `category_id = GROCERIES_ID`, `amount_minor = +500000` (increases expense ledger by ₦5,000.00).
$$\sum = -500000 + 500000 = 0$$

For an internal transfer of ₦20,000 from Bank to Cash:
1. `Movement 1`: `account_id = GTB_ID`, `amount_minor = -2000000`.
2. `Movement 2`: `account_id = CASH_WALLET_ID`, `amount_minor = +2000000`.
$$\sum = -2000000 + 2000000 = 0$$
Note: Category ID is null for pure transfers, ensuring transfer neutrality in monthly expense reporting.
