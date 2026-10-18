# ARCHITECTURE SPECIFICATION
## Personal Life OS (v2.0 Engineering Edition)

### 1. Architectural Philosophy
Personal Life OS is an **offline-first, single-owner, zero-backend, privacy-centric personal operating system**. It is designed with clean architecture principles, featuring strict separation between:
1. **Domain Layer:** Pure Dart business logic, value objects, immutable domain entities, calculations (financial double-entry, recurrence, sleep validation, recovery rules). Free from Flutter framework dependencies and database libraries.
2. **Data Layer:** Drift/SQLite typed data access objects (DAOs), versioned migrations, repository implementations, secure local storage adapters (AES-GCM encryption, Keychain/Keystore key derivation), CSV parsers, backup engine.
3. **Application / Service Layer:** Controllers, StateNotifiers / Riverpod providers, notification orchestrators, lifecycle monitors, audit loggers.
4. **Presentation Layer:** Flutter UI widgets, Material 3 design system, responsive layouts, accessibility semantic nodes, screen contracts (`SCR-01..58`).

```
+-------------------------------------------------------------+
|                     Presentation Layer                      |
| (Screens SCR-01..58, Widgets, Modals, Responsive Shell)     |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|              Application / State Management                 |
| (Riverpod Notifiers, UI State, Event Handlers)              |
+-------------------------------------------------------------+
         |                                          |
         v                                          v
+-----------------------+              +-----------------------+
|     Domain Layer      |              |   Platform Services   |
| (Entities, Calculators|              | (Local Notifications, |
|  Recurrence, Recovery)|              |  Clock, File Storage) |
+-----------------------+              +-----------------------+
         ^                                          ^
         |                                          |
+-------------------------------------------------------------+
|                        Data Layer                           |
| (Drift / SQLite DB, Repositories, Migrations, Encryption)   |
+-------------------------------------------------------------+
```

### 2. Core Subsystems

#### 2.1 Storage & Encryption Subsystem (`core/database`)
- **Engine:** SQLite with Drift typed ORM.
- **Encryption at Rest:** Sensitive entities (journal bodies, financial amounts, private spiritual notes) use authenticated AES-256-GCM encryption with keys derived via OS secure storage (Android Keystore / iOS Keychain).
- **Integrity & Migrations:** Forward versioned schema migrations (`schema_migrations.dart`) with schema snapshots and pre-migration database checkpoints.

#### 2.2 Financial Double-Entry Engine (`features/finance`)
- **Integer Minor Units:** All currency values are stored as 64-bit integer minor units (kobo for NGN). Never IEEE-754 binary floating point.
- **Double-Entry Journal:** Every financial action posts balanced `LedgerMovement` entries where `Sum(postings) = 0`.
- **Transfers:** Pure internal balance movements between asset accounts. Zero impact on revenue/expense reporting.
- **Reversals & Edits:** Destructive updates post an atomic reversal transaction linked to the original `transaction_id`, preserving audit integrity.

#### 2.3 Recurrence & Scheduling Engine (`core/utils/recurrence_engine.dart`)
- **Series & Exceptions:** Recurring routines and events are defined as rules (`RecurrenceRule`). Instances are generated on demand. Edits create `OccurrenceException` records rather than cloning unbounded future database rows.
- **Complex Patterns:** Daily, specific weekdays, monthly nth-weekday, last Friday-Saturday-Sunday monthly bundles.
- **Deduplication:** The Friday of the monthly 3-day weekend fast is deduplicated against the weekly Friday fast (`BR-03`).
- **Cross-Midnight:** A session starting at 23:00 on day D and ending at 01:00 on day D+1 calculates a positive 120-minute duration and is properly represented across both day views (`BR-07`).

#### 2.4 Commitment Recovery Engine (`features/recovery`)
- **Philosophy:** Recovery and consistency over punishing streak losses.
- **Deterministic Rules:** Detects neglected tasks and habits when inactivity exceeds configurable grace periods (default 3 days).
- **Anti-Overwhelm:** Surfaces a maximum of 3 recovery cards per day on the dashboard.
- **Actionable Choices:** Do 5 minutes now, reschedule, simplify target, pause, or cancel intentionally. Zero automated shaming or spiritual moral scores.

#### 2.5 Local Notification & In-App Activity Subsystem (`core/services/notification_service.dart`)
- **Local Reminders:** Scheduled via platform-native local notifications.
- **Resilience:** Gracefully falls back to an in-app reminder inbox (`SCR-55`) when OS permissions are denied (`BR-11`). Reconciles upcoming alarms on app launch and timezone transitions.

#### 2.6 Backup & Atomic Restore Subsystem (`core/services/backup_service.dart`)
- **Container:** Password-protected encrypted container using Argon2id key derivation and AES-GCM authenticated encryption.
- **Atomic Restore:** Backup archives are extracted into an isolated staging directory, schema and SHA-256 checksums are verified against `BackupManifest`, and the active database is replaced via an atomic swap (`BR-13`).
