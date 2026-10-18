# SCREEN CONTRACTS SPECIFICATION
## Personal Life OS (v2.0 Engineering Edition)

This document formalizes the input/output contracts, query sources, write operations, and validation requirements for all 58 screens defined in PRD Section 21 and Section 36.

---

### Phase 1: Authentication, Onboarding & Setup

#### SCR-01: Local Unlock / App Gate
- **Entry Path:** App launch, return from background after idle timeout (>5 min), or cold start.
- **Query Sources:** `UserProfile`, `Setting(key: 'app_lock_enabled')`, `Setting(key: 'pin_hash')`.
- **Inputs:** 4-6 digit numeric PIN or biometric prompt trigger.
- **Validation:** PIN must match PBKDF2/Argon2 salt+hash stored in secure storage. Lockout with incremental backoff after 5 failures.
- **Writes:** Updates `AuditEvent(type: 'auth_success' | 'auth_fail')`.
- **Destinations:** On success -> `SCR-06 (Today Dashboard)`. First launch -> `SCR-02 (Welcome & Onboarding)`.
- **States:** Normal, Error (incorrect PIN with attempts remaining), Lockout countdown.

#### SCR-02: Welcome & Onboarding Wizard
- **Entry Path:** First app launch when `UserProfile` does not exist.
- **UI Sections:** Hero banner, core value proposition (consistency & recovery over punishing streaks), setup flow overview.
- **Inputs:** "Get Started" button, "Restore from Backup" action.
- **Destinations:** "Get Started" -> `SCR-03 (Privacy & Storage Explanation)`, "Restore" -> `SCR-57 (Backup & Restore)`.

#### SCR-03: Privacy, Storage & Security Walkthrough
- **Entry Path:** Flow from `SCR-02`.
- **UI Sections:** Offline-first guarantees, zero cloud transmission, local encryption, encrypted backup advice, no account requirement.
- **Validation:** User must acknowledge device loss risk (explicit checkbox before continuing).
- **Destinations:** -> `SCR-04 (Profile & Aspirations Setup)`.

#### SCR-04: Profile & Aspirations Setup
- **Entry Path:** Flow from `SCR-03` or `SCR-56 (Settings)`.
- **Inputs:** Owner display name (optional), default locale (default: en_NG), currency (default: NGN ₦), timezone (default: Africa/Lagos), week start (Monday default), 12/24-hour clock, bedtime target, waking target (default 6:00 AM), morning devotion duration (default 120 mins).
- **Validation:** If bedtime to waking window is <= 5 hours (e.g., 1:00 AM to 6:00 AM), displays a gentle non-blocking health caution advising rest preservation (`BR-05`, `FR-ON-05`).
- **Writes:** Creates or updates `UserProfile` and `Setting` rows in `AppDatabase`.
- **Destinations:** -> `SCR-05 (Workspace Configuration)`.

#### SCR-05: Workspaces & Baseline Habit Setup
- **Entry Path:** Flow from `SCR-04`.
- **Inputs:** Select active workspaces (Personal [locked], Bems Group [COO], Henovate [Founder], + Custom), starter habits activation level (Starter minimum vs Full aspiration with load warning).
- **Writes:** Seeds `Workspace` entities and initial `RoutineTemplate` rows (wake up, prayer, bible study, clothes planning, laundry).
- **Destinations:** -> `SCR-06 (Today Dashboard)`.

---

### Phase 2: Today, Planning & Recovery

#### SCR-06: Today Dashboard
- **Entry Path:** Primary bottom navigation tab 1.
- **Query Sources:** `UserProfile`, `RoutineTemplate` joined with today's `Completion`, top 3 prioritized `Task` where `scheduled_date = today`, upcoming `CalendarEvent`, active `FastPlan`, today's posted `LedgerTransaction` count/total.
- **UI Sections:**
  1. Header: Greeting, owner name, current date, Africa/Lagos time, privacy blur toggle.
  2. Spiritual / Fasting Banner: Active fast (Mon/Fri or last-weekend) with gentle hydration notice.
  3. Today's Top 3 Priorities: High-impact tasks with 1-tap completion/reschedule.
  4. Daily Timeline Widget: Scrollable time blocks with status indicators.
  5. Commitment Recovery Queue (Max 3 cards): Suggested gentle next actions for neglected items.
  6. Quick Actions Floating Bar: Fast Expense, Quick Task, Quick Journal, Focus Timer.
- **Writes:** Atomic task completion, routine check-off, low-energy mode toggle.
- **Empty States:** "No scheduled obligations today — enjoy your day or capture a new task".

#### SCR-07: Daily Timeline
- **Entry Path:** Tap on timeline card or header on `SCR-06`.
- **Query Sources:** `CalendarEvent`, `TimeBlock`, `RoutineOccurrence` for selected date.
- **Actions:** Start session, mark complete, reschedule, skip with reason.
- **Special Logic:** Supports cross-midnight blocks (23:00 to 01:00) spanning two days with positive duration (`BR-07`).

#### SCR-08: Morning Planning Wizard
- **Entry Path:** Prompted on `SCR-06` before 11:00 AM or manual tap.
- **UI Sections:** Workspace switcher (Personal, Bems Group, Henovate), backlog picker, top 3 selector, workload capacity meter.
- **Validation:** Warns if total estimated task time exceeds available working hours.
- **Writes:** Sets `Task.is_top_priority = true`, `Task.scheduled_date = today`.

#### SCR-09: Evening Review Wizard
- **Entry Path:** Prompted on `SCR-06` after 7:00 PM or manual tap.
- **UI Sections:** Completed achievements, carry-forward overdue items with explicit reschedule date, daily spending total, gratitude/lessons reflection.
- **Writes:** Creates immutable `Review(kind: 'daily')` and updates rescheduled task histories (`BR-02`).

---

### Phase 3: Calendar & Recurrence

#### SCR-10: Calendar Views (Day, Week, Month)
- **Entry Path:** Bottom navigation tab 2 ("Plan").
- **Query Sources:** `CalendarEvent`, `RecurrenceRule`, `OccurrenceException`, `FastPlan`.
- **Features:** Day agenda, 7-day multi-column week view, monthly grid with occurrence dots and fasting badges.
- **Actions:** Date navigation, tap day to inspect, FAB to create event.

#### SCR-11: Event & Recurrence Editor
- **Entry Path:** FAB on `SCR-10` or tap event.
- **Inputs:** Title, category, start datetime, end datetime, all-day toggle, recurrence rule (daily, weekdays, specific days, nth weekday, last weekend), reminder offset, workspace.
- **Validation:** End must be after start (or next day for cross-midnight), valid recurrence parameters.
- **Occurrence Edit Choices:** "This occurrence only", "This and following", "Entire series" (`FR-CAL-04`).

---

### Phase 4: Tasks, Inbox & Recovery

#### SCR-12: Task Inbox & Universal Capture
- **Entry Path:** Bottom navigation tab 3 ("Tasks") -> Inbox tab.
- **Query Sources:** `InboxItem` where status is un-triaged.
- **Actions:** 1-tap capture, swipe to triage into task, project, or delete.

#### SCR-13: Task List & Filtering
- **Entry Path:** "Tasks" tab -> Active / Scheduled / Blocked / Archived views.
- **Filters:** By workspace (Personal, Bems Group, Henovate), priority (Urgent, High, Medium, Low), tags, due date.
- **Actions:** Batch select, batch move workspace, batch archive.

#### SCR-14: Task Detail & History Editor
- **Entry Path:** Tap any task row.
- **Inputs:** Title, description, next physical action, due date, estimated minutes, checklist items, parent project, dependencies, manual assignee.
- **Features:** Shows historical activity log with reschedule history and reasons (`FR-TS-08`).

#### SCR-15: Quick Capture Sheet
- **Entry Path:** Global floating action button on any screen.
- **Inputs:** Fast text input, workspace picker, quick date chip (Today, Tomorrow, Weekend).
- **Validation:** Title cannot be empty.

#### SCR-16: Focus Timer (Pomodoro / Custom)
- **Entry Path:** Quick action on `SCR-06` or task detail.
- **Inputs:** Duration preset (5m, 25m, 50m, custom), linked task.
- **Features:** Pause/resume, break alert, interrupted session logging to `TimeLog`.

#### SCR-17: Commitment Recovery Queue
- **Entry Path:** Header card on `SCR-06` or recovery badge on `SCR-13`.
- **Query Sources:** Overdue items with inactivity > 3 days (`REC-101..110`).
- **Options per card:** "Do 5 minutes now", "Reschedule with date", "Reduce target/frequency", "Pause for 7 days", "Cancel intentionally".
- **Rule:** Never more than 3 cards displayed at once to avoid emotional overwhelm (`BR-02`).

#### SCR-18: Goals Overview
- **Entry Path:** "More" -> Goals.
- **Query Sources:** `Goal` partitioned by workspace with progress towards target metrics.

---

### Phase 5: Professional Workspaces & Projects

#### SCR-19: Workspaces Hub
- **Entry Path:** "More" -> Workspaces.
- **Features:** Segregated views for Bems Group (COO), Henovate (Founder), and Personal. Workload planner capacity meter.

#### SCR-20: Projects List
- **Entry Path:** Workspaces -> Selected Workspace -> Projects.
- **Query Sources:** `Project` entities filtered by active workspace.

#### SCR-21: Project Detail & Milestones
- **Entry Path:** Tap project from `SCR-20`.
- **Features:** Objectives, target launch date, deliverables list, ordered milestones, linked tasks.

#### SCR-22: Delegated Follow-Up Tracker
- **Entry Path:** Professional workspace menu.
- **Query Sources:** `FollowUp` entities (person name, requested commitment, date sent, expected response date, status).
- **Note:** Private ledger only; zero automated emails or messaging (`FR-WK-05`).

---

### Phase 6: Spiritual Life

#### SCR-23: Spiritual Life Overview
- **Entry Path:** "More" -> Spiritual.
- **UI Sections:** Gentle continuity chart (sessions engaged, zero guilt badges), today's prayer slots, Bible reading tracker, upcoming fast dates.

#### SCR-24: Prayer Journal
- **Entry Path:** Spiritual -> Prayer Journal.
- **Inputs:** Prayer theme, scripture reference, confidential notes, start/end timer, answered prayer status.

#### SCR-25: Bible Study & Scripture Reference Planner
- **Entry Path:** Spiritual -> Bible Study.
- **Inputs:** Book, chapter, verse reference, study questions, observations, personal application. Offline reference planner.

#### SCR-26: Meditation & Reflection Editor
- **Entry Path:** Spiritual -> Meditation.
- **Inputs:** Key passage, "What stood out", spiritual takeaways, action steps.

#### SCR-27: Fasting Planner & Calendar
- **Entry Path:** Spiritual -> Fasting.
- **Query Sources:** Recurring Mon/Fri rules + monthly 3-day last-weekend template.
- **Special Logic:** Deduplication: Friday in the 3-day fast counts once (`BR-03`). Hydration and health caution notices.

#### SCR-28: Sermon Notes & Spiritual Library
- **Entry Path:** Spiritual -> Sermon Notes.
- **Features:** Preacher name, church/event, sermon title, scripture text, practical insights.

---

### Phase 7: Lifestyle, Hygiene & Wardrobe

#### SCR-29: Daily Personal Care & Hygiene
- **Entry Path:** "More" -> Lifestyle -> Daily Care.
- **Items:** Morning teeth, bathing, grooming, making bed, evening teeth, hydration.

#### SCR-30: Chores & Household Order
- **Entry Path:** Lifestyle -> Chores.
- **Query Sources:** Recurring chores (laundry, room cleaning, bedsheets, trash, supplies).

#### SCR-31: Sunday Wardrobe Planner
- **Entry Path:** Lifestyle -> Wardrobe Planner.
- **Features:** Outfit selection for Monday through Sunday across month boundaries (`BR-04`). Garment catalog with clean/laundry status.

#### SCR-32: Household Supplies & Shopping List
- **Entry Path:** Lifestyle -> Supplies.
- **Inputs:** Item name, category, current quantity, minimum reorder threshold, shopping list check-off.

---

### Phase 8: Financial Ledger & Control

#### SCR-33: Finance Overview
- **Entry Path:** Bottom navigation tab 4 ("Finance").
- **Query Sources:** Total balance across accounts in NGN (minor units / kobo), monthly income vs expense, budget remaining, upcoming bills.
- **Privacy Mode:** Tap eye icon to mask amounts (`₦ ••••••`).

#### SCR-34: Accounts & Balances
- **Entry Path:** Finance -> Accounts.
- **Features:** Cash, Bank, Mobile Wallet, Savings, Liabilities. Opening balance and real-time ledger balance.

#### SCR-35: Transactions List & Filters
- **Entry Path:** Finance -> Transactions.
- **Filters:** By account, category, date range, transaction type (income, expense, transfer, refund).

#### SCR-36: Add / Edit Transaction Editor
- **Entry Path:** FAB on Finance or Quick Expense button.
- **Inputs:** Type (Expense, Income, Transfer), amount (keypad in ₦), account, category, date/time, merchant/memo, receipt attachment.
- **Validation:** Amount > 0, account and category valid. Checks for duplicate candidate within 24h (`FR-FN-10`).
- **Writes:** Creates balanced `LedgerTransaction` and `LedgerMovement` rows atomically (`Section 30`).

#### SCR-37: Monthly Budgets & Rollovers
- **Entry Path:** Finance -> Budgets.
- **Inputs:** Monthly allocation per category in ₦, rollover policy toggle. Shows spent vs remaining.

#### SCR-38: Bills & Recurring Subscriptions
- **Entry Path:** Finance -> Bills.
- **Features:** Upcoming bills calendar, due day, reminder offset. Projected bills never count as actuals until paid (`BR-14`).

#### SCR-39: Debts & Liabilities Ledger
- **Entry Path:** Finance -> Debts.
- **Features:** Creditor name, principal, remaining balance, repayment schedule, manual payment entry linking ledger.

#### SCR-40: Savings Goals
- **Entry Path:** Finance -> Savings Goals.
- **Features:** Goal target amount, target date, progress bar. Transfers into savings do not double-count as expenses (`FR-FN-08`).

#### SCR-41: Financial Insights & Period Closing
- **Entry Path:** Finance -> Insights / Reports.
- **Features:** Net cashflow, spending by category, Friday spending review, month-end closing statement.

#### SCR-42: CSV Import & Export
- **Entry Path:** Finance -> Import/Export.
- **Features:** CSV file picker, column mapping preview, duplicate detection, atomic dry run and rollback on failure (`FR-FN-12`).

---

### Phase 9: Learning, Digital Discipline & Wellness

#### SCR-43: Reading Library
- **Entry Path:** "More" -> Learning -> Library.
- **Query Sources:** Books with format, total pages, current page progress, reading status.

#### SCR-44: Book Detail & Reading Sessions
- **Entry Path:** Tap book from `SCR-43`.
- **Inputs:** Log reading session (start page, end page, minutes read, key takeaways).

#### SCR-45: Structured Learning Plans
- **Entry Path:** Learning -> Study Plans.
- **Features:** Course/subject modules, lessons checklist, spaced review reminders.

#### SCR-46: Detail-Review Checklist
- **Entry Path:** Learning -> Detail Checklist or linked from professional tasks.
- **Items:** Calculation verification, proofreading, recipient check, attachments verified.

#### SCR-47: Digital Discipline Dashboard
- **Entry Path:** "More" -> Digital Discipline.
- **Features:** Allowed social media windows, distraction trigger log, quiet hours configuration. Transparent OS limits notice (`FR-DD-03`).

#### SCR-48: Sleep & Health Check-ins
- **Entry Path:** "More" -> Health.
- **Inputs:** Bedtime, waking time, actual sleep vs bed time, exercise notes, hydration check. Health caution if sleep < 5 hours (`FR-HL-02`).

#### SCR-49: Relationship Reminders
- **Entry Path:** "More" -> Relationships.
- **Features:** Contact list (family, mentors), days since last contact, reminders to reach out manually.

#### SCR-50: Character & Values Journal
- **Entry Path:** "More" -> Character.
- **Inputs:** Weekly reflection on humility, patience, integrity, self-control. Zero moral scoring.

---

### Phase 10: Notes, Search, Analytics & Settings

#### SCR-51: Daily Journal & Rich Notes
- **Entry Path:** "More" -> Journal.
- **Features:** Encrypted journal entries, auto-save draft, bidirectional links to tasks/scripture.

#### SCR-52: Global Search & Results
- **Entry Path:** Search icon in top bar.
- **Query Sources:** Full-text search across tasks, notes, scripture, projects, and transactions.

#### SCR-53: Insights Analytics
- **Entry Path:** "More" -> Insights.
- **Features:** Habit consistency trends, focus time totals, finance variance. Live persistent data only.

#### SCR-54: Weekly & Monthly Review Wizard
- **Entry Path:** "More" -> Reviews.
- **Features:** Guided multi-step review: accomplishments, open commitments, budget closing, wardrobe, next week plan.

#### SCR-55: Notification Center & Activity Inbox
- **Entry Path:** Bell icon in top bar.
- **Features:** In-app reminder inbox ensuring zero missed alerts when OS notification permissions are denied (`FR-NT-05`).

#### SCR-56: Settings, Appearance & Security
- **Entry Path:** "More" -> Settings.
- **Inputs:** Dark/light/system theme, accent color, PIN lock configuration, inactivity lock timer, timezone, currency.

#### SCR-57: Encrypted Backup & Restore
- **Entry Path:** Settings -> Backup & Restore.
- **Features:** Export encrypted ZIP (Argon2id + AES-GCM), integrity checksum verification, atomic restore to staging before swap (`BR-13`).

#### SCR-58: Help, Diagnostics & Data Wipe
- **Entry Path:** Settings -> Diagnostics.
- **Features:** Database record counts, storage usage, integrity check, multi-step destructive wipe confirmation.
