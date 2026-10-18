# PERSONAL LIFE OS — COMPREHENSIVE PRODUCT REQUIREMENTS DOCUMENT

**Document version:** 2.0 — Detailed Engineering Edition | **Date:** 18 October 2026  
**Product type:** Private, offline-first personal life management mobile application  
**Primary user:** Single individual (owner)  
**Primary platform:** Android; architecture must support iOS  
**Recommended technology:** Flutter + Dart, SQLite via Drift, encrypted-at-rest data architecture, native local notifications  
**Default locale:** English (Nigeria), NGN, Africa/Lagos, 12-hour display configurable  
**Status:** Detailed functional + engineering contract (not a completed implementation)

## 0. IMPLEMENTATION DIRECTIVE TO THE AI SOFTWARE BUILDER

Build a **working, production-minded application**, not a landing page, mock-up, wireframe, static dashboard, or UI-only prototype. Implement every functional module, persistent local data store, business rule, state transition, form validation, recurring-event engine, tests, backup/restore, and platform integration defined here. Do not silently skip requirements. Where integrations or OS capabilities are unavailable, provide honest fallbacks and document the limitation. Build the app so its core experience needs **no hosted backend or internet**. Avoid placeholder buttons, fake metrics, unimplemented navigation, fabricated transaction data, and hard-coded completion statistics.

Deliver: complete Flutter project; documented folder structure; reproducible setup/build steps; versioned local database migrations; seed/sample data confined to an explicit demo mode; unit/widget/integration tests; Android debug and release build instructions; iOS build instructions (requiring macOS/Xcode for native signing); privacy and backup documentation; feature checklist mapping requirements to code and tests; known limitations. Never claim that every feature is completed unless it has working implementation and passing acceptance tests.

The product owner's schedule and spiritual practices are user-defined aspirations, **not compulsory defaults**. Prioritize sustainable consistency, accessibility, privacy, safety, and ease of use.

---

## 1. PRODUCT VISION, GOALS, AND NON-GOALS

### 1.1 Vision
One private, calm, mobile-first personal operating system connecting daily routines, spiritual life, personal hygiene, chores, time, tasks, commitments, work responsibilities, finances, reading, study, social media self-regulation, health, relationships, character, and reflection. It is designed for a person who starts activities enthusiastically but struggles to sustain them when motivation declines. Its core value is **reliable continuation and recovery**, not punishing streaks.

### 1.2 Primary outcomes
1. See what truly matters today, without overwhelming clutter.
2. Capture any commitment instantly; translate it into a concrete next action and scheduled slot.
3. Execute tasks for Bems Group, Henovate, and personal projects without commingling their workspaces.
4. Track personal money and obligations accurately, offline, in NGN.
5. Maintain prayer, fasting, Bible study, reflection, and reading without treating spiritual maturity as a points competition.
6. Maintain predictable hygiene, laundry, cleaning, dress preparation and healthy routines.
7. Notice neglected commitments and return to them without guilt or losing all prior progress.
8. Reflect on progress weekly/monthly; adjust overambitious plans.
9. Operate reliably on one phone, with encrypted portable backups.

### 1.3 Success measures (locally measured, user-private)
- Percentage of planned commitments completed, rescheduled, skipped deliberately, or overdue, with denominators clearly shown.
- Average number of days between a missed commitment and next action (recovery latency).
- Daily expense-log coverage (user self-report; no claim of bank completeness).
- Number and age of overdue tasks by workspace.
- Weekly planning/review completion.
- Routine sustainability: user-adjusted targets and rest preservation, not gamified worship time.

### 1.4 Explicit non-goals for initial release
No banking connections, automatic transaction ingestion, real-time bank transfers, social networking, public leaderboards, automated spiritual judgments, medical diagnosis, surveillance of other apps, or required cloud account. Do not infer objective spiritual status from devotional duration. No automatic access to personal/employer accounts.

---

## 2. PLATFORMS, ARCHITECTURE, OFFLINE FIRST

### 2.1 Stack
- Flutter stable channel, Dart, clean feature-first modular architecture with repository and service layers.
- SQLite with Drift (or equivalently well-maintained typed SQLite layer); migrations with forward schema versioning.
- Securely stored local secrets using OS Keychain/Android Keystore. Protect database and attachments at rest with a documented encryption approach; do not imply that ordinary unencrypted SQLite is secure. Do not hard-code keys.
- State management: Riverpod or a well-documented equivalent; declarative routing; strongly typed domain entities.
- Native notifications through well-supported Flutter plugins with platform-specific configuration and version compatibility checks.
- Filesystem for attachments/export/import, with encrypted backup format.
- Device-first app with zero required API calls on critical paths. Use optional network only when explicitly enabled for updates, off-device backup, sync, or imported content.

### 2.2 Data model and privacy boundaries
All personal data locally owned by the user. Partition all content by workspace where applicable (Personal, Bems Group, Henovate, optional others). Separate personal financial records from professional expenditure logs. Support device PIN/biometric gate, with accessible fallback and recovery warning. Sensitive spiritual journals and finances should be hideable from dashboard previews and locked separately if user chooses.

### 2.3 Offline guarantees
After first install, the following must work in airplane mode: onboarding, unlock, dashboard, habits, routines, tasks, projects, financial entries, search, journaling, read/notes, fasting schedules, local notifications (subject to OS policies), analytics, settings, encrypted local export/import. All CRUD operations must remain usable offline. No spinner waiting for network; no network-only fonts, images, Bible text or critical assets.

### 2.4 Backup strategy
- Encrypted full backup to user-selected local file via OS share/save picker (password-derived encryption with strong KDF and authenticated encryption; e.g., Argon2id + AES-GCM, platform-tested).
- Include DB, attachments, preferences, and schema/app version manifest. Omit platform-bound keys and secrets; re-enroll authentication on restore.
- Explain lost-password consequences: no recovery without backup passphrase.
- Manual export, optional periodic reminder to back up, restore preview, checksum/integrity checks, schema compatibility, migration, and post-restore verification.
- Optional user-initiated copy to their own file/cloud provider via OS file picker/share sheet; no mandatory hosted backend.
- JSON/CSV human-readable exports for relevant modules; never represent plaintext export as private/encrypted.
- Device loss or OS data clearance can destroy unbacked-up data. Display this warning in onboarding.

### 2.5 Optional future sync
Define repository interfaces to support eventual encrypted multi-device sync, but **do not create a fake sync toggle**. Sync must remain disabled/nonexistent until implemented with conflict resolution, user auth, transport security, encryption, deletion handling, schema versioning and backup recovery. Native local notification scheduling must not require sync.

---

## 3. USER ROLES, WORKSPACES, NAVIGATION

### 3.1 Roles
- **Owner:** sole administrator, access to all modules and settings; only user initially.
- **No staff/admin/mentor access in V1.** Optional sharing/export is manually initiated; journals remain private by default.

### 3.2 Workspaces
- Personal: private life, spiritual practice, hygiene, home, finance, reading and health.
- Bems Group: COO tasks, delegated follow-ups, meetings, projects, deliverables.
- Henovate: founder responsibilities, prospect follow-ups, proposals, product work and growth goals.
- Additional user-defined workspaces; custom icons/colors; each task/project/category tagged to one workspace or explicitly marked cross-workspace.
- No automatic company-calendar or company-data access; optional integrations require explicit user authorization and separation.

### 3.3 Information architecture
Bottom navigation (maximum five): **Today**, **Plan**, **Tasks**, **Finance**, **More**. More opens Spiritual, Work/Projects, Learning, Lifestyle, Health, Relationships, Insights, Journal, Search, Settings, Backup. Floating/global “+” quick-capture action on major screens. Adapt layouts to small Android screens, tablets and responsive desktop in future. Provide dark/light/system mode and accessibility.

### 3.4 Global UX principles
- Start in under 3 taps for expense, task, quick journal, or commitment capture.
- Avoid clutter and aggressively colored “failure” warnings.
- Use explicit empty, loading, success, validation and error states.
- Offer clear edit/delete/undo and confirmation for destructive financial/import/restore actions.
- Show dates and times with timezone and preferred display, and amount formatting with ₦ and grouping.
- Search all owner-controlled records, filter by workspace/date/status/tags.

---

## 4. ONBOARDING AND PERSONAL CONFIGURATION

**FR-ON-01** Create local owner profile: display name optional, locale, timezone (default Africa/Lagos), currency (default NGN), week starts Monday/Sunday, 12/24-hour clock, personal goals and optional profile photo.

**FR-ON-02** Privacy walkthrough: local storage, backup risk, optional lock/passcode/biometric, no external server required, notification permissions are optional. No account signup.

**FR-ON-03** Guided setup for waking target, desired sleep window, devotional target, workspaces, weekly recurring chores, financial categories and personal priorities. Allow “skip for now” for any non-critical field.

**FR-ON-04** Set custom baseline using supplied aspirations as editable example templates only:
- wake at 6:00 AM;
- morning meditation/prayer target to configure (historically desired two hours; starting at 6 AM if chosen);
- Bible study begins at 9:00 PM;
- requested night prayer 11:00 PM–1:00 AM;
- regular fasting Monday and Friday;
- three-day monthly fast on final Friday–Sunday, counting the Friday once;
- laundry weekends, clothing preparation Sunday evening;
- dedicated work for Bems Group and Henovate;
- reduced recreational social media;
- daily reading, hygiene, finance logging and review.

**FR-ON-05** Warn if configured sleep opportunity is implausibly short; explain that a 1 AM finish and 6 AM wake leave at most five nighttime hours; never silently replace user-defined hours. Offer editable alternatives (reduce/alternate late prayer, earlier main sleep, protected additional sleep), but no coercion or diagnosis. The application must allow schedules to be saved with an unobtrusive health warning and not assume 5 hours is adequate.

**FR-ON-06** Offer a starter routine with only a few initially active commitments, with gradual activation of more habits; ability to activate full plan immediately with a confirmation explaining load.

---

## 5. TODAY DASHBOARD AND PLANNING

**FR-TD-01** Personalized date/time header, next scheduled activity, today's top three priorities, meetings, routines, prayer/fasting flags, outstanding tasks, quick expense button, daily focus and review prompt.

**FR-TD-02** Timeline with time blocks; tap for details; start/complete/skip/reschedule; differentiate planned, in-progress, completed, skipped, cancelled, overdue. Pending uncompleted activities should not vanish at midnight.

**FR-TD-03** Dynamic morning plan: prompt owner to select up to three high-impact tasks, one next action each; allow work balance view Bems/Henovate/personal.

**FR-TD-04** Evening review with completed, deferred, unfinished, upcoming obligations, finance log summary, lessons and tomorrow prep; save daily snapshot.

**FR-TD-05** Low-energy/day-overloaded mode: owner voluntarily selects a reduced achievable day without erasing original goals. Preserve critical medication or mandatory responsibilities if user designated them as protected; app does not prescribe medical actions.

**FR-TD-06** Widgets/cards can be reordered/hidden, with sensitive amounts/spiritual notes blurred when privacy mode enabled.

**FR-TD-07** Live data only: all cards and progress computed from persistent records, no fabricated metrics.

---

## 6. CALENDAR, ROUTINES, RECURRENCE AND TIME BLOCKING

**FR-CAL-01** Day/week/month calendar views; custom event types: routine, appointment, task block, fast, prayer, study, chore, meeting, birthday/reminder.

**FR-CAL-02** Create, duplicate, edit, delete events with title, description, start/end, timezone, all-day option, recurrence rule, until/count, reminder offsets, workspace, importance, privacy, attached task/project and notes.

**FR-CAL-03** Recurrence: daily, weekdays, specific days, weekly, monthly nth weekday, last Friday/Saturday/Sunday of month, yearly, finite range, custom interval, exception/skip dates. Handle cross-midnight events, DST/timezone transitions, duplicate occurrences, leap years and month ends. Store recurring series plus occurrence exceptions rather than unbounded pre-generation.

**FR-CAL-04** Explicit behavior when editing: this occurrence / this and future / entire series.

**FR-CAL-05** Detect overlapping events; warn, suggest adjustment, allow intentional overlap with explicit acceptance. Protect configurable rest blocks.

**FR-CAL-06** Date navigation and rescheduling with drag/drop where supported, accessible edit dialog on all devices.

**FR-CAL-07** Dedicated time-block categories and weekly planned-vs-actual comparison (actual only if user logs it or timer is used).

**FR-CAL-08** Notification scheduler creates/cancels/reschedules OS-local notifications as changes occur; reconcile upcoming reminders on app launch, device reboot where platform permits, timezone change and permission change; OS platform-specific limits must be documented and tested. Never guarantee delivery in Do Not Disturb, battery restriction or denied permission.

**FR-CAL-09** Holidays or imported calendars only through optional import; no external source dependency.

---

## 7. TASKS, IDEAS, COMMITMENTS, AND FOLLOW-THROUGH

**FR-TS-01** Universal inbox: quick text task/idea capture, optional voice-to-text via device only where available, date, attachment, workspace. Preserve raw capture until triaged.

**FR-TS-02** Convert idea to actionable task/project with outcome, next physical action, priority, effort estimate, deadline, scheduled time block, tags, notes, checklist, attachments, recurring cadence and linked goals.

**FR-TS-03** Status: inbox, next, scheduled, in-progress, blocked, awaiting response, completed, cancelled, archived. Overdue is derived from date and status, not destructive state.

**FR-TS-04** Dependencies, subtasks, checklist, notes, link to parent project/goal, manual assignee name for professional follow-ups (not another authenticated user).

**FR-TS-05** Focus session/timer (5/25/50 custom minutes) with pause/resume, optional break, interrupted session logging; count actual focus time only when timer used.

**FR-TS-06** Daily top-three priority selection; task carry-forward across days with explicit rescheduling instead of duplication.

**FR-TS-07** Commitment Recovery Engine: detect neglected items based on configurable inactivity/overdue thresholds; show private recovery queue, not shame messaging; prompt “do five minutes,” “make next action smaller,” “reschedule,” “delegate,” “pause,” “cancel intentionally.” User owns every action; no auto-delete or auto-complete.

**FR-TS-08** Track created date, original due date, revised due dates, postponement count, last activity, reason for postponement (optional), completed timestamp and historical changes for meaningful analytics.

**FR-TS-09** Support standing responsibilities and one-off commitments distinctly; recurrence generation must never create duplicate active instances after repeated app restarts.

**FR-TS-10** Batch move, tag, archive, export, search and filters.

---

## 8. SPIRITUAL LIFE

**FR-SP-01** Prayer sessions: planned time, actual optional start/end, prayer theme, Scripture references, private notes, reflections, status and optional reminder.

**FR-SP-02** Bible study: book, chapter, passage reference, optional locally entered text/notes, study questions, observations, interpretation, application, action item, review date, bookmarks and tags. Do not bundle copyrighted Bible translations without permission/license. Users may enter/import legally obtained text. Basic passage-reference planning must work offline.

**FR-SP-03** Meditation journal: passage/reference, what stood out, reflection, application and follow-up; not mere timer tracking.

**FR-SP-04** Fasting planner: Monday/Friday recurring, monthly three-day last-Friday-through-Sunday template with deduplication on Friday, special fasting plans, user-defined start/end and type, private personal intentions and reflection. Never instruct user to fast medically unsafely; allow pause/exemption and hydration/health notices without guilt.

**FR-SP-05** Spiritual reading library, sermon notes, prayer topics, answered-prayer reflections and periodic review; user controls whether to log any answered prayers or outcomes.

**FR-SP-06** Gentle continuity insights (planned vs engaged) but no spiritual-ranking score, public streak leaderboard or assertion of divine approval.

**FR-SP-07** Sensitive spiritual notes excluded from system notification previews and home widget unless explicitly enabled.

**FR-SP-08** Teach schedule as preference; prayer sessions may be shortened/rescheduled without app declaring failure. Provide weekly meditation themes/notes manually, not algorithmically fabricated doctrinal interpretation.

---

## 9. PERSONAL CARE, HOUSEHOLD ORDER, WARDROBE

**FR-LF-01** Daily personal care checklist: bathing, teeth morning/evening, grooming, clothes, making bed, tidying, hydration/nutrition reminders as user selects.

**FR-LF-02** Weekly household plan: laundry, bedsheets, room, bathroom, desk, shoes, waste disposal, household supplies; frequencies adjustable.

**FR-LF-03** Sunday wardrobe planner: outfit list for Monday–Sunday; reusable garments, clean/dirty/in-laundry status (optional), preparation checklist. This is optional inventory, not mandatory clothing photo capture.

**FR-LF-04** Recurring chores with snooze, delegated/outsourced, skipped-with-reason, checklist, estimated effort and progress.

**FR-LF-05** Supplies register with manual quantities, minimum reorder reminder, shopping list; optional and no purchase API.

**FR-LF-06** Weekend preparation screen bundles laundry, house cleaning, outfits, weekly priorities, financial review and upcoming commitments.

---

## 10. PROFESSIONAL WORKSPACES AND PROJECTS

**FR-WK-01** Bems Group workspace and Henovate workspace with independent project dashboards, tasks, goals, follow-ups, time blocks, documents/links and outcomes.

**FR-WK-02** Project lifecycle: idea, discovery, planned, active, paused, blocked, completed, archived. Project owner, client/organization optional, deliverables, milestones, due dates, linked subtasks, blockers and notes.

**FR-WK-03** Recurring COO routines (operations review, leadership check-ins, approvals, delegation, reports) and Henovate routines (prospect research, proposals, client discovery, product architecture, delivery review); all templates editable and off by default until approved.

**FR-WK-04** Workload planner warns when daily estimated capacity exceeds configured available work hours. Do not merge Bems and Henovate records without explicit cross-workspace action.

**FR-WK-05** Delegated follow-up tracker: person/name, commitment, requested date, expected response, reminders, last contact, status. This is a private tracker, not a system for sending messages automatically.

**FR-WK-06** Weekly COO and founder reviews with achievements, decisions, pending approvals, risks, blockers and next-week priorities.

**FR-WK-07** Time logs with manual/manual-timer source transparency and optional weekly hours by workspace. No invented timesheets.

---

## 11. FINANCE MANAGEMENT

### 11.1 General rules
All values stored as integer minor units or precise fixed decimal, never binary floating point for currency. Default currency NGN; future multicurrency support optional with explicit exchange conversion, but never silently combine currencies. **This is a personal ledger, not a regulated banking application.** No connection to financial institutions or automated transfers in V1.

### 11.2 Accounts and categories
**FR-FN-01** Create cash, bank, wallet, savings and other manual accounts with opening balance and optional masked label. Hide/show balances. Bank credentials must never be requested.

**FR-FN-02** Categories: food, transport, accommodation, utilities, giving, family, clothing, grooming, healthcare, education, subscriptions, business-related personal costs, debt, savings and customizable categories/subcategories/tags.

**FR-FN-03** Transactions: income, expense, transfer between own accounts, adjustments, refund/reversal; date/time, amount, merchant/payee, note, category, account, attachment/receipt, planned/unplanned, recurring source, created/edited timestamps. Transfers should affect two accounts but not count as income or spending.

**FR-FN-04** Transaction edit/delete and reversal must correctly recompute balances, totals and budgets, avoid double-counting, and preserve audit events where appropriate. Confirm destructive changes.

**FR-FN-05** Recurring incomes/expenses and bills: due day, expected amount, reminder, paid/partially paid/overdue, rollover and stop conditions. Never record projected bills as paid actuals until confirmed.

**FR-FN-06** Financial obligations: loans/debts owed or payable, lender, principal, remaining balance, due schedule, manual repayments, evidence, notes; no automatic interest unless explicitly configured. Avoid misleading payoff calculations.

**FR-FN-07** Budgets per category and month, optional envelopes, fixed/variable allocation, planned vs actual and remaining amount; overspend advisory without blocking essential spending.

**FR-FN-08** Savings targets: goal amount, contributions, withdrawals, target date and progress. Transfers into savings should not double-count as expenditures.

**FR-FN-09** Insights: total income, actual expenses, net cash flow, budget variance, category distribution, account balances, upcoming bills, debt balances, savings contribution and trend. Show source and coverage caveat: totals reflect recorded transactions only.

**FR-FN-10** Fast-add expense in <=3 taps from dashboard for common category/account; detect duplicate possible entries by date/amount/merchant and ask rather than silently discarding.

**FR-FN-11** Attach receipts offline; safe local file copies, configurable size limit and compression. No OCR necessary.

**FR-FN-12** CSV import/export with preview, field mapping, duplicate review, dry run, row-level errors and rollback on failure; no external server.

**FR-FN-13** Weekly Friday spending review and month-end closing summary: expense trends, discretionary categories, obligations, savings, budget adjustments; allow late-entry corrections and auditable re-close.

**FR-FN-14** Personal/work segregation: any work-related paid expense is tagged to a workspace and reimbursement status, but employer finance remains separate from personal balances unless actually reimbursed. No company finance automation without explicit separate requirements.

---

## 12. READING, STUDY, LEARNING, AND KNOWLEDGE

**FR-LN-01** Reading library: title, author, type (Bible, faith, professional, technical, general), format, total pages/chapters, progress, start/end dates, notes, source, tags and reading status.

**FR-LN-02** Daily/weekly reading targets as pages/minutes/sessions; capture actual progress; adjustable target; no fabricated percentage if total unknown.

**FR-LN-03** Structured study plans: topic, modules, lessons, resources, time blocks, progress, spaced manual review, comprehension notes and application tasks.

**FR-LN-04** Capture learning highlights, ideas, linked tasks, follow-up reading and optional export to Markdown/PDF via local rendering.

**FR-LN-05** Detail-focus checklist before significant deliverables: accuracy, completeness, dates/names, calculations, spelling, evidence, attachments and final review. Attach to professional tasks/projects.

**FR-LN-06** Study focus sessions connected to time logs, breaks, and goals.

---

## 13. DIGITAL DISCIPLINE

**FR-DD-01** Define recreational social media allowed windows, daily self-reported usage target, no-scroll periods, distraction triggers and personal rules.

**FR-DD-02** Prompt to log self-reported distraction occurrences; optional weekly summary with honest labeling.

**FR-DD-03** App must *not claim* to monitor or block other apps without platform permissions and implementation. If Android usage-access or focus-mode integration is later built, request explicit OS permissions, show scope, and provide fallback. iOS cannot promise identical monitoring/control because platform access differs.

**FR-DD-04** Quiet hours for Personal Life OS notifications and notification density controls; urgent reminders should still respect OS policies and user settings.

---

## 14. HEALTH, REST, RELATIONSHIPS, CHARACTER

**FR-HL-01** Voluntary sleep schedule (planned bedtime, waking target, actual bedtime/wake, nap logs), estimated duration with clear distinction between time in bed and actual sleep; no medical-grade sleep detection claim.

**FR-HL-02** If sleep windows are consistently short, display non-judgmental reminder to protect recovery; don't automatically change user commitments.

**FR-HL-03** Exercise/movement logs, meals/hydration as optional check-ins, wellbeing notes, medical appointment reminders; no diagnostic advice.

**FR-RL-01** Relationship contact reminders for family, mentors and important people; store names/relationship/notes and last contact; no automatic messaging or invasive tracking.

**FR-CH-01** Character development journal with values (humility, patience, integrity, punctuality, self-control), weekly reflection prompts, examples of conduct and application of Scripture; no moral score or negative identity labels.

**FR-HL-04** Respect rest days and graceful pause; fasting/logging should not encourage dehydration, dangerous restriction or compensatory behavior.

---

## 15. JOURNAL, NOTES, SEARCH, FILES

**FR-JR-01** Daily journal entries with timestamp, workspace/private category, text, tags, optional attachment; template prompts and freeform.

**FR-JR-02** Notes attach to task, project, Scripture study, book, finance transaction or standalone category; bidirectional navigation where possible.

**FR-JR-03** Full-text search across authorized local records; filters by type/date/workspace; local index with protected sensitive content.

**FR-JR-04** Files and attachments accessible offline, encrypted appropriately, with file type/size validation, safe deletion/reference cleanup, backup inclusion and clear export paths.

---

## 16. NOTIFICATIONS, ESCALATIONS, AND RECOVERY ENGINE

**FR-NT-01** Local reminders for scheduled events, fast starts, prayer/study, laundry, clothes planning, bills, tasks and reviews. Multiple optional offsets with per-category controls.

**FR-NT-02** Notification buttons where supported: view, complete, snooze. Securely handle actions after app lock, avoid exposing secret data.

**FR-NT-03** Adaptive nudges based on explicit user preferences, not opaque AI scoring. Examples: task postponed three times => suggest breaking down; missed routine twice => offer smaller minimum; expenses not logged => gentle evening prompt; overdue bill => clearly labeled reminder.

**FR-NT-04** Quiet mode, rest times, frequency limits, snooze, temporary pause, vacation/travel mode. No notification flood, shame language or manipulation.

**FR-NT-05** Keep an in-app reminders/activity inbox because OS notifications may be denied/missed. Distinguish scheduled, delivered (only if verifiable), dismissed, missed and viewed; do not fake OS delivery proof.

**FR-NT-06** Test Android exact alarm permission policies, reboot rescheduling, Doze/battery optimization, timezone and locale changes. Graceful fallback to inexact or in-app reminders where required.

---

## 17. ANALYTICS, REPORTS AND PERIODIC REVIEWS

**FR-AN-01** Daily/weekly/monthly views of intended vs completed routines, missed/rescheduled reasons, top-priority completion, focus time, postponed task age, reading, chores, workspaces, personal expenses and budgets.

**FR-AN-02** Graceful empty states; no claims based on missing financial or time-tracking data.

**FR-AN-03** Weekly review: accomplishments, unresolved commitments, decluttering, finances, next week outfits, spiritual/character reflection, health/rest and top priorities.

**FR-AN-04** Monthly review: financial totals and variance, project completion, consistency trends, recurring load, neglected goals, savings, reading, planned fasting and reset for next month.

**FR-AN-05** Display thoughtful explanations and definitions for metrics; allow exporting report to PDF/CSV/Markdown offline where practical.

**FR-AN-06** No scores for spiritual worth or moral worth; analytics are for self-understanding and operational improvement.

---

## 18. SETTINGS AND CUSTOMIZATION

**FR-ST-01** Edit profile, timezone, currency display, week start, theme, font/text scaling, accent theme, 12/24-hour clock, navigation order and dashboard cards.

**FR-ST-02** Manage custom categories, templates, workspaces, privacy, notifications, recurring defaults, time windows and weekly review day.

**FR-ST-03** Lock using optional biometric/passcode and inactivity timer; hide sensitive content in app switcher where supported.

**FR-ST-04** Manage local data lifecycle: export, encrypted backup, restore, wipe all data (with multi-step confirmation), database diagnostics, storage use and version info.

**FR-ST-05** Clear onboarding reset, feature tour, help guide and offline documentation.

---

## 19. DOMAIN DATA MODEL (MINIMUM)

Each mutable record should have UUID primary key, created_at, updated_at, deleted_at/tombstone if applicable, local timezone semantics where relevant, and optional workspace_id. Build normalized tables and migrations rather than one massive JSON blob.

**Core:** UserProfile, Workspace, Setting, Category, Tag, Attachment, AuditEvent.

**Calendar:** CalendarEvent, RecurrenceRule, RecurrenceException, Reminder, ReminderAction, TimeBlock, FocusSession, TimeLog.

**Execution:** InboxItem, Task, TaskChecklistItem, TaskDependency, TaskActivity, TaskRescheduleHistory, Commitment, Goal, Milestone, Project, ProjectLink, FollowUp.

**Spiritual:** PrayerSession, PrayerTopic, ScriptureStudy, ScriptureReference, MeditationEntry, FastPlan, FastOccurrence, SermonNote, SpiritualReflection.

**Lifestyle:** Routine, RoutineOccurrence, HabitCompletion, Chore, HouseholdSupply, WardrobeItem, OutfitPlan, CareChecklist.

**Finance:** FinancialAccount, FinancialCategory, Transaction, TransactionSplit, TransferPair, Budget, BudgetPeriod, SavingGoal, SavingsContribution, Debt, DebtPayment, Bill, RecurringFinanceRule, FinancialStatementSnapshot, Receipt.

**Learning:** Book, ReadingSession, LearningPlan, Lesson, StudyNote, KnowledgeHighlight, ReviewPrompt.

**Health/relationships:** SleepLog, WellbeingEntry, ExerciseEntry, MealCheckin, Person, RelationshipReminder, CharacterReflection.

**Journals/analytics:** JournalEntry, ReviewEntry, MetricSnapshot, NotificationLog, BackupManifest, ImportBatch, ImportRowResult.

### 19.1 Important relational rules
- Transaction.account_id points to a real owner-created account, split lines total exactly to transaction amount, and transfer legs balance.
- Every occurrence of a recurring routine has unique `(series_id, occurrence_local_date_or_instance_key)` to prevent duplicate completions.
- Recurrence exceptions carry original occurrence identity so moving an event does not create a duplicate.
- Workspace separation enforced in repository queries and UI, not merely by color coding.
- Attachment references must remain valid through backup/restore, archiving and deletion.
- Task history records due-date and state changes; duplicate quick taps must be idempotent.
- Audit logs cannot be used as a substitute for database transaction integrity.

---

## 20. BUSINESS RULES AND EDGE CASES

**BR-01** Completion state is distinct from a task being merely scheduled or viewed.

**BR-02** A rescheduled item retains identity and history; it is not automatically marked completed or recreated as a duplicate.

**BR-03** For the recurring fasting template, last Friday–Sunday must produce three distinct dates only and Friday counted once against regular Friday fasting.

**BR-04** A Sunday outfit plan can cover Monday–Sunday of the next calendar week even across month/year boundary.

**BR-05** Past-due recurring items must remain visible for review, but notification scheduling must not flood users with all historic missed instances after reopening the app.

**BR-06** Expense account balance = opening balance + posted income + inbound transfers - posted expenses - outbound transfers ± adjustments, with refunds/reversals correctly handled. Transfers excluded from income/expense reports. Non-posted planned bills excluded.

**BR-07** A midnight-crossing prayer/event, e.g. 23:00–01:00, uses correct next-day end and cannot silently produce negative duration.

**BR-08** When owner crosses timezones, maintain intent for wall-clock routines (e.g., 6 AM locally) and preserve timestamped event history; ask whether to retain home-time for travel-specific events.

**BR-09** Daylight saving changes must not corrupt events, amounts or notifications.

**BR-10** Monthly recurring activities on dates that do not exist use an explicit policy (last valid day / skip), visible to user.

**BR-11** When notification permissions are denied, the app remains usable and uses in-app due lists, not repeated coercive prompts.

**BR-12** Deleted/archived items must not appear in active reminders but may be included in history until purged.

**BR-13** Backup restore must reject corrupted/wrong-passphrase data without partially replacing the active database. Restore to staging, validate, then atomic swap.

**BR-14** Distinguish recorded from projected expenses and manual from verified financial entries. No fake financial data.

**BR-15** User-defined devotion targets must be modifiable without deleting journals or past adherence records.

**BR-16** No automatic sending messages, creating calendar events externally, uploading files or transferring funds without explicit permission.

---

## 21. UI SCREEN INVENTORY

1. Splash / local unlock.
2. Welcome and onboarding wizard.
3. Privacy/storage/backup explanation.
4. Profile and initial goals.
5. Workspace configuration.
6. Today dashboard.
7. Daily timeline.
8. Morning planning.
9. Evening review.
10. Calendar day, week and month.
11. Event/recurrence editor.
12. Task inbox.
13. Task list/filters.
14. Task detail/editor and history.
15. Quick capture.
16. Focus timer.
17. Commitment recovery queue.
18. Goals overview.
19. Workspaces overview.
20. Projects list.
21. Project details/milestones.
22. Delegation/follow-up tracker.
23. Spiritual overview.
24. Prayer journal.
25. Bible study and Scripture reference planner.
26. Meditation/reflection editor.
27. Fasting calendar and fasting plan editor.
28. Sermon/spiritual notes.
29. Lifestyle/hygiene today.
30. Chores and household planner.
31. Wardrobe weekly preparation.
32. Supplies/shopping list.
33. Finance overview.
34. Accounts and balances.
35. Transactions list/detail.
36. Add/edit income/expense/transfer.
37. Budgets and category allocations.
38. Bills/subscriptions.
39. Debts and repayments.
40. Savings goals.
41. Financial analysis/period closing.
42. Import/export transactions.
43. Reading library.
44. Book detail, sessions, highlights.
45. Learning plans and lessons.
46. Detail-review checklist.
47. Digital discipline dashboard.
48. Sleep/health check-ins.
49. Relationships reminders.
50. Character/values reflection.
51. Journal and notes.
52. Global search/results.
53. Insights analytics.
54. Weekly/monthly review wizard.
55. Notifications and in-app reminder inbox.
56. Settings/privacy/appearance.
57. Backup/export/restore and validation preview.
58. Help and diagnostics.

Each screen must specify loading/empty/error/validation states and route to working persistence functions. All key operations available on phones smaller than 6 inches.

---

## 22. NON-FUNCTIONAL REQUIREMENTS

**NFR-01 Privacy:** no analytics SDK, crash uploads, background tracking or cloud transmission by default. Any diagnostic sharing is opt-in, with sensitive content excluded.

**NFR-02 Security:** encrypted at-rest user data and backups; secure key management; app-lock screen; parameterized SQL queries; safe attachment/file validation; no plaintext secrets in logs; secret notification previews off by default.

**NFR-03 Reliability:** transactional writes, database migration rollback plan, atomic backup restores, app crash recovery, de-duplication and reconciliation of notifications after reboot and permission changes.

**NFR-04 Performance:** cold launch aim <3 seconds on a representative mid-range Android phone with moderate dataset (target, verify); routine interactions feel immediate; 10,000+ task/transaction records handled with pagination/indexes.

**NFR-05 Accessibility:** readable contrast, screen-reader labels, dynamic font scaling, semantic controls, large touch targets, non-color-only status indicators, keyboard navigation where supported.

**NFR-06 Battery:** avoid always-on services and unnecessary background polling; schedule OS-supported notifications efficiently.

**NFR-07 Storage:** report usage, receipt size controls, vacuum/cleanup safely, warn when insufficient space for backup.

**NFR-08 Internationalization:** Africa/Lagos default, Nigerian number/currency formatting, future locale extensibility, robust timezone rules.

**NFR-09 Offline:** no forced account creation, no API calls to render dashboard, no hidden network dependency for essential features.

**NFR-10 Portability:** Android APK/install flow and iOS-capable codebase. Signing, iOS testing, and publishing depend on Apple tooling/accounts and cannot be performed on Windows alone for a native iOS release.

**NFR-11 Testability:** repositories and clock injectable; use fake clock for midnight, DST and recurrence tests. Deterministic calculations for money and occurrence generation.

---

## 23. REQUIRED TEST MATRIX

Automated tests must cover:
1. Clean first launch, offline onboarding and app lock/unlock.
2. CRUD persistence across app process termination/restart for every module.
3. Monday/Friday fasting plus last-Friday-to-Sunday in months with different month-end weekdays; no duplicate Friday.
4. Cross-midnight 23:00–01:00 event; accurate elapsed duration.
5. March/February/leap-year month-end recurrence and travel timezone changes.
6. Individual recurrence exception vs entire-series edit.
7. Local reminder create/update/cancel; denied notification permissions; reopen/reboot behavior within OS constraints.
8. Task reschedule history and recovery queue; no duplicate recurring task after restart.
9. NGN financial math, edits, transfers, refunds, reversals, splits, budgets, recurring bills, savings and debt repayments.
10. CSV import duplicate preview/error handling and rollback.
11. Privacy settings, masking in previews, file validation and encrypted backup wrong password/integrity rejection.
12. Restore to new installation and round-trip equivalence of records and attachments.
13. Screen reader semantics and large text on dashboard, task, finance and navigation views.
14. Airplane-mode execution of critical user journeys.
15. Thousands of transactions/tasks without slow list/analytics operations.
16. Workspace separation and no accidental leakage between Bems/Henovate/Personal.
17. Every navigational button and important form submits, persists, validates and updates UI.
18. Date/time edit of 6 AM recurring devotion and 9 PM Bible study; preserve previous history.
19. Device clock changes and app returning from extended inactivity.
20. Simulated crash mid-backup/restore; live database remains intact.

### End-to-end acceptance scenarios
**A. Typical Sunday:** owner records expenses, does laundry, prepares five weekday outfits, previews Monday fasting and selects Bems/Henovate priorities. Close app, reopen offline: all saved and reminders scheduled.

**B. Low-motivation Wednesday:** owner has missed study twice; recovery card suggests 10-minute minimum and rescheduling without deleting prior plan; completion updates metrics but does not imply spiritual standing.

**C. Finance month end:** add income, expenses, account transfer, refund, savings transfer and pending bill; reports tally posted records, transfers not counted as expenses, budget differences precise.

**D. Device replacement:** user exports encrypted backup to own chosen destination and restores it on another supported device with correct password; history, journals, projects, receipts and categories match.

**E. No connectivity:** device in airplane mode for a week; task, finance, routines, reading and journal work correctly; no blocked buttons or waiting indicators.

---

## 24. DELIVERY PLAN, PRIORITY AND DEFINITION OF DONE

All modules in this PRD are part of **full product scope**. Implement as an integrated sequence to reduce breakage, but do not treat completion of the initial milestone as completion of the full app.

**Build order:**
1. Architecture, domain models, encrypted storage strategy, migrations, routing, theme, onboarding, app lock, backups foundation.
2. Calendar/recurrence, routines, local reminders and today dashboard.
3. Task inbox, projects/workspaces, commitment recovery, timers and reviews.
4. Spiritual module and life/household/wardrobe.
5. Full manual financial ledger and reports.
6. Learning, digital discipline, health, relationships, character and journals.
7. Analytics, search, exports, user preferences, cross-module linking.
8. Accessibility, comprehensive testing, performance tuning, documentation and release packaging.

**Definition of done for each module:** All listed screens and core CRUD actions function; offline persistence tested; edge cases included; no fake displays; validation and error states; keyboard and screen-reader accessibility; unit/widget/integration tests; export/backup inclusion; navigation integrated; data migration considered; documented limitations.

**Final handoff requires:**
- Complete source code with instructions and dependency lockfile.
- Buildable Android app and tested install instructions.
- iOS build procedure with clear environment/signing requirements.
- Local database schema and migration scripts.
- Example user manual including backup/recovery.
- Acceptance test checklist with PASS/FAIL evidence and unresolved issues.
- Privacy statement explaining storage and optional features.
- Distinction between implemented, partial and unavailable capabilities.

---

## 25. ACCEPTANCE CRITERIA: RELEASE GATE

Do **not** label this product finished merely because its dashboard renders. Release candidate may be approved only when:

- User can complete real daily scenarios **entirely offline**.
- Expense records and actual balances persist correctly, including account transfers and refunds.
- Calendar recurrence, fasting overlap, and cross-midnight hours calculate correctly.
- Reminders are scheduled locally and platform limitations are clearly explained.
- All required modules have operational forms, state, history and navigation.
- Daily/weekly/monthly reviews use actual data and produce accurate totals.
- Encrypted backup is tested successfully to file and restored successfully on fresh install.
- No mandatory online account/server, demo-only endpoints, fake financial metrics or placeholder buttons.
- Tests run and are recorded, critical failures fixed, and remaining limitations listed transparently.

## 26. DEVELOPER HANDOFF PROMPT

> Build **Personal Life OS** precisely according to this PRD as a complete Flutter local-first Android application with iOS-ready architecture. Treat the entire file as the source of truth. Produce runnable source code, schemas, migrations, complete modules, actual forms and flows, native local notifications, tested encrypted backup/restore, unit/widget/integration tests, and release documentation. Do not substitute designs, screenshots, mockups, fake dashboards or sample records for functionality. Use honest fallbacks for OS-restricted features. Work in small verified implementation steps internally, but do not declare completion until every item in the acceptance matrix has been exercised and the full feature coverage report is available. If a required capability cannot be built in the available environment, provide the best working alternative and mark it explicitly incomplete instead of silently skipping it.

---

## 27. IMPORTANT IMPLEMENTATION NOTES AND OPEN ASSUMPTIONS

- This PRD resolves platform as a **single-owner, offline-first Flutter phone app**. It does not presume the owner wants public App Store distribution.
- For Android, use local APK first. For iPhone, native builds require a compatible Apple development environment and provisioning; use Xcode/macOS for build/signing.
- The app should **not** require recurring hosting fees. Optional off-device backup uses files chosen by user, not necessarily a proprietary cloud backend.
- Certain advanced features (e.g., monitoring usage of other apps, background push from remote services, bank transaction sync and multi-device synchronization) cannot be delivered with identical functionality entirely offline and across operating systems; these remain optional and must be described truthfully.
- Imported Scripture translations require appropriate copyright licensing. A reference/notes planner can be implemented without copyrighted text.
- Spiritual schedules and fasting preferences are editable and should not prescribe unsafe sleep or fasting. The previously proposed 11 PM–1 AM prayers plus 6 AM wake-up is explicitly flagged as leaving at most five nighttime hours.
- This PRD is comprehensive in intended scope, but no specification can guarantee an AI will successfully implement every feature in one pass. Test results and working builds, not the AI's claims, determine completeness.


# PART II — DETAILED ENGINEERING AND ACCEPTANCE ANNEXES


## 28. REQUIREMENTS TRACEABILITY AND DELIVERY CONTRACT

Every requirement shall have a unique traceable ID, implementing files, automated test IDs and a status: Not Started / Implemented / Verified / Blocked / Deferred by explicit scope decision. Full product scope is not fulfilled while any required capability remains Blocked or Deferred. A build report must distinguish compile success from device-level verification.

**Release evidence:** `requirements_matrix.csv` columns `requirement_id,module,priority,screen_ids,data_entities,implementation_files,test_ids,test_result,manual_result,notes`; `test_results.md`; `known_issues.md`; `screenshots/`; `build/` artifact and SHA-256; platform versions; dependency license register. Acceptance is a signed-off review by the owner against the matrix, not an AI claim.

**Cross-cutting interaction contract:** Every screen has loading/empty/populated/validation/failure states; every write operation is durable and transactional where needed; destructive actions use clear confirmation and recoverable soft deletion where possible; back-navigation never silently discards edited content; date/time and currency render consistently; accessibility labels describe real controls; all screens respect app lock and workspace privacy. No analytics or tracking SDK by default.

**Offline-first invariant:** The visible record immediately follows successful local commit, never an optimistic display that could disappear silently. If commit fails, show nontechnical actionable error and preserve the user's unsaved input. App upgrades must not corrupt records. Use deterministic, documented migrations.


## 29.1. MODULE SPECIFICATION — TODAY: TODAY HOME, QUICK CAPTURE AND ADAPTIVE DAY PLAN

**Requirement prefix:** `TODAY-`  
**Functional responsibility:** Daily agenda, priority cards, due tasks, routines, contextual fasting badge, finance capture, restorative prompts, overdue queue, day-end closure.

**Minimum user journey:** Create item, reorder priorities, check off, undo, reschedule, switch date, switch workspace, open record and return without losing context. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** No plan; one or more overdue items; hundreds of tasks; change of timezone; missed previous day; negative schedule capacity; offline reboot.

**Acceptance contract:** Today dashboard renders under two seconds on typical supported hardware with 500 tasks, and all widgets reflect committed data after restart. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.2. MODULE SPECIFICATION — CAL: CALENDAR, AVAILABILITY AND TIME-BLOCKING

**Requirement prefix:** `CAL-`  
**Functional responsibility:** Day/week/month views, recurring activities, conflict detection, exceptions, blackout dates, focus blocks, reminders and completion records.

**Minimum user journey:** Create single or recurring activity; edit occurrence versus series; move time block; skip an instance; mark done; change timezone; export ICS. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** DST transition in travel timezone; 11PM–1AM across dates; duplicate Monday/Friday fasts; last-weekend detection; two reminders same minute; notification permission denied.

**Acceptance contract:** Recurrence occurrences and edits consistent in time and occurrence lists, preserving exceptions. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.3. MODULE SPECIFICATION — TASK: TASKS, INBOX AND COMMITMENTS

**Requirement prefix:** `TASK-`  
**Functional responsibility:** One-tap capture, clarify next action, deadline, due time, estimates, prerequisites, attachments, subtasks, importance, notes, lifecycle, archived items.

**Minimum user journey:** Capture; triage; assign workspace; schedule; start focus session; defer with reason; delegate as personal record; complete; reopen; archive. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Task overdue while app closed; recurring task completed early; recurrence change; multiple due dates; accidental deletion; missing attachment.

**Acceptance contract:** No task disappears solely because it is overdue, and no completed recurring instance is double-counted. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.4. MODULE SPECIFICATION — SPIR: SPIRITUAL PRACTICE

**Requirement prefix:** `SPIR-`  
**Functional responsibility:** Prayer blocks, Bible reading plans, passage references, study journal, meditation notes, fasting, gratitude, prayer list, answered-prayer reflections.

**Minimum user journey:** Set aspiration and minimum; create recurring fast; mark practice done/partial/skipped; add confidential note; review without judgments; edit schedule. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Overlap Friday fast; fasting 3-day final weekend across month; missed prayer; sleep conflicts; duplicate Bible plan day; copyrighted text absent.

**Acceptance contract:** No algorithm labels religious status or penalizes private devotion; all progress indicators represent only user-reported actions. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.5. MODULE SPECIFICATION — LIFE: HYGIENE, HOME, WARDROBE

**Requirement prefix:** `LIFE-`  
**Functional responsibility:** Personal care routines, supplies, bedsheets, laundry schedule, room chores, wardrobe catalog, weekly outfits, recurring reminders.

**Minimum user journey:** Assign chore, mark completion, snooze, build outfit schedule, swap garments, note washing or repair. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Unwashed clothing selected; travel day; repeated laundry skipped; no wardrobe entries; insufficient garments.

**Acceptance contract:** Wardrobe suggestions are advisory and user-selectable, not forced or inferred from sensitive data. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.6. MODULE SPECIFICATION — WORK: PROFESSIONAL WORKSPACES

**Requirement prefix:** `WORK-`  
**Functional responsibility:** Bems COO, Henovate Founder, personal initiatives; projects, milestones, deliverables, stakeholders, meetings, delegated follow-ups and review.

**Minimum user journey:** Create project; break down milestones; assign actions; attach files; weekly summary; filter workspaces; track next follow-up without sending messages. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Cross-workspace task; confidential notes; project cancellation; incomplete milestone dependency; renamed workspace.

**Acceptance contract:** Personal expense and work expenditure never merge unless deliberate and separately categorized. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.7. MODULE SPECIFICATION — FIN: MONEY AND PERSONAL FINANCIAL CONTROL

**Requirement prefix:** `FIN-`  
**Functional responsibility:** Accounts, cash/wallet balances, income, expense, transfer, liabilities, loan repayment, savings goals, recurring commitments, budgets, receipts, reports.

**Minimum user journey:** Create accounts; record transaction; edit; reverse; split; transfer; record refund; attach receipt; reconcile ledger; budget rollover; export. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Decimal rounding; accidental double entry; cross-currency; transfer fee; future dated item; reversal; partial refund; split category; negative balance.

**Acceptance contract:** All balances and statements reconcile with immutable transaction movement history and mathematically consistent totals. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.8. MODULE SPECIFICATION — LEARN: READING AND SKILL DEVELOPMENT

**Requirement prefix:** `LEARN-`  
**Functional responsibility:** Book/course catalog, goals, sessions, page tracking, subject notes, bookmarks, spaced review prompts, learning projects.

**Minimum user journey:** Add resource; log session; attach notes; set reading goal; pause; finish; review knowledge; report progress. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Unknown page count; reread book; duplicate course; reading without page count; abandoned learning goal.

**Acceptance contract:** Reading metrics distinguish minutes, pages, sessions and completion percentage; never fabricate progress. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.9. MODULE SPECIFICATION — DIG: DIGITAL DISCIPLINE

**Requirement prefix:** `DIG-`  
**Functional responsibility:** Intentional app-use commitments, distraction diary, personal screen time manual log, app-specific goals, focus mode guidance.

**Minimum user journey:** Choose distraction target; log slip; plan allowed windows; use timer; review patterns. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** OS usage permission unavailable; iOS cannot provide comparable access; no screen-time data; deleted logs.

**Acceptance contract:** Manual alternative is fully functional; avoid claiming native OS blocking or automatic usage analysis without actual integration. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.10. MODULE SPECIFICATION — HEALTH: SLEEP, WELLBEING, EXERCISE

**Requirement prefix:** `HEALTH-`  
**Functional responsibility:** Bedtime and wake preferences, sleep journal, exercise activities, hydration optional, breaks and overcommitment prompts.

**Minimum user journey:** Log sleep, edit entry, mark exercise, review fatigue notes, adjust reminder settings. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Overlapping sleep intervals; sleep crossing midnight; insomnia; time zone travel; health status not disclosed.

**Acceptance contract:** Only wellness logs, no medical diagnosis; flag insufficient sleep plans without enforcing behavior. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.11. MODULE SPECIFICATION — REL: RELATIONSHIPS AND CHARACTER

**Requirement prefix:** `REL-`  
**Functional responsibility:** Contact-free relationship reminders, commitments to family and mentors, gratitude, values, character reflections.

**Minimum user journey:** Create follow-up, review, mark reached out manually, reflect on values and growth. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Sensitive notes; no contact permissions; recurring outreach postponed; sharing accidental.

**Acceptance contract:** No automatic messaging/contact access; entries private by default. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.12. MODULE SPECIFICATION — JRN: NOTES, ATTACHMENT AND SEARCH

**Requirement prefix:** `JRN-`  
**Functional responsibility:** Private journals, tags, links to tasks and verses, attachments, search, encrypted exports.

**Minimum user journey:** Write; auto-draft locally; tag; link; search; redact previews; export selected items. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Large note; image attachment deleted outside app; export with sensitive journal; filename collision.

**Acceptance contract:** Autosave cannot silently discard text; locked content excluded from notifications/previews. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.13. MODULE SPECIFICATION — RECV: COMMITMENT RECOVERY AND REVIEWS

**Requirement prefix:** `RECV-`  
**Functional responsibility:** Overdue detection, recovery suggestions, reason logging, next-small-action planning, daily/weekly/monthly reviews.

**Minimum user journey:** Detect missed action; present reschedule/simplify/drop options; confirm user choice; log reason; assess trend. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Multiple misses; user on leave; recurring event during travel; reminder overload; low engagement for weeks.

**Acceptance contract:** Never silently reschedule or increase commitments; user authorizes changes; no shaming scores. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 29.14. MODULE SPECIFICATION — SEC: AUTHENTICATION, BACKUP, SETTINGS

**Requirement prefix:** `SEC-`  
**Functional responsibility:** Local PIN/biometrics, lock timer, profile, secure exports, encrypted backup and restore, migration, data deletion.

**Minimum user journey:** Set lock; change PIN; backup with passphrase; inspect restore manifest; restore fresh device; delete/export data. Every create/edit form requires Cancel, Save, appropriate validation, unsaved-change handling, immediate read-back and persistent reload. Every index/detail view provides search or contextual filter when scale warrants it. All actions are keyboard- and screen-reader-usable.

**Detailed business rules:**
1. Each record has an immutable UUID, owner ID, created/updated timestamps, optional deleted timestamp, revision, workspace linkage (where applicable), and validation status. Creation or update must be atomic; attempts with invalid input must not write partial records.
2. Recurring instances store independent completion metadata and reference the recurrence definition; changing the rule cannot erase historical completions.
3. Each item exposes one explicit next action and optional estimated duration. User can reduce target, defer with reason, skip deliberately or archive; analytics distinguish those outcomes.
4. Contextual reminders require explicit opt-in, local scheduling, editable lead times and quiet-hours compliance; notification tap deep-links to the exact record when possible.
5. Data is searchable and exportable according to privacy settings. Deletion is confirmed; items linked elsewhere use a clearly stated unlink/retain/cascade policy.

**Expected failure and boundary scenarios:** Forgot PIN; lost backup password; corrupted file; disk full; migration interrupted; OS notification revoked.

**Acceptance contract:** Full restoration verified on fresh install; app never claims passphrase recovery or automatic backup without explicit implementation. Test at least create, reload, edit, completion, recurrence where applicable, delete/undo, airplane mode, app restart, and backup/restore with the module's data.

**Screen-level coverage:** Index/list, detail, create/edit, context filters, history/activity, reports where needed, empty state, errors and settings. Screens must share common components but never hide functionality behind dead controls.


## 30. FINANCIAL LEDGER — ACCOUNTING, VALIDATION AND CALCULATION CONTRACT

**Authoritative model:** A lightweight double-entry movements ledger, not a collection of mutable account totals. Money values are stored as integer minor units (kobo for NGN), not binary floating point. Every transaction has stable `transaction_id`, effective date, created date, type, status, note, source, optional external reference, receipt ids and one or more balanced ledger movements. User-facing accounts include cash, bank, wallet, savings, liabilities and opening equity with user-friendly labels. Do not require banking integration.

**Invariant:** Sum of signed posting amounts per currency for a balanced journal transaction equals zero. Income adds to selected asset and corresponding income category; expense reduces asset and increases expense category; transfer decreases source asset and increases target asset; fees are separately categorized; refunds reverse original allocation and retain original linkage; liability repayments distinguish principal and interest. Reports count expenses by expense category, not transfers.

**Transactions and examples:** (A) NGN 50,000 income to bank -> bank +50,000, income +50,000 in reporting terms; (B) NGN 3,500 meal -> bank -3,500, food spending +3,500; (C) NGN 10,000 bank to cash -> bank -10,000, cash +10,000, spending unchanged; (D) NGN 2,000 refund -> cash/bank +2,000, linked expense net -2,000; (E) NGN 5,000 loan repayment with NGN 4,000 principal and NGN 1,000 interest -> liability principal -4,000, asset -5,000, interest expense +1,000. Underlying debit/credit polarity is defined in repository documentation, with tests for these equivalent balances.

**Validation:** amounts positive except intentionally signed correcting ledger lines; maximum precision based on currency; reject invalid number entry, overflows and missing account/category; allow user-configurable negative asset balances with warning; duplicate detector uses date+amount+account+memo and offers confirmation, never auto-discard; future-dated entries clearly distinguished from posted balance; transaction editing results in atomic reversal plus replacement or auditable revision rather than overwriting movement history.

**Budgets:** `budget(scope=category|group, period=month, allocatedMinor, rolloverPolicy, alertThreshold)`. Spent = posted net expenses during period, excluding transfers and unposted future expenses. Remaining = allocated + eligible rollover - net spend. Budget alerts are informational, not payment controls.

**Savings:** Savings transfers are not expenses. Track goal target, target date, contributions, withdrawals and linked savings account independently; avoid double-counting.

**Reports:** day/week/month/custom filters; opening, inflows, outflows, transfers, closing; net cashflow excludes internal transfers; category spending and trends; liabilities, recurring obligations and savings; CSV data plus human-readable PDF only if separately implemented. Exports label currency, timezone, selected dates and filters.

**Tests FIN-101…FIN-120:** transfer neutrality, split expense balancing, partial refund, split refund, reversal, edit audit, precision, insufficient funds warning, fees, recurring bill idempotency, currency mismatch rejection, account archive, income classification, budget rollover, month edge, timezone edge, export/import reconciliation, backup parity, duplicate detection and multi-account total.


## 31. SCHEDULER — PRECISE RECURRENCE AND TIME CONTRACT

Separate `RoutineTemplate`, `RecurrenceRule`, `OccurrenceException`, `OccurrenceCompletion`, `ReminderIntent` and `TimeBlock`. All time rendering honors IANA timezones; persist UTC instants for appointments and local wall-time + timezone for recurring routine intent. Never hard-code UTC+1 because user may travel.

**Supported recurrence:** daily, selected weekdays, weekly, monthly day-of-month, last weekday of month, nth weekday, last Friday/Saturday/Sunday bundle, interval every N days/weeks/months, specific dates, end after occurrence count, end date, excluded dates. Month with unavailable day must use user-selected skip/clamp policy; default skip and explain.

**Specific user templates, editable and disabled until confirmed:** Monday fast; Friday fast; three-day last-weekend fast; Sunday clothes planning; Saturday laundry; 6 AM wake routine; 9 PM Bible study; 11 PM–1 AM prayer aspiration. The Friday inside the monthly three-day period may count simultaneously toward both rules while maintaining distinct purpose tags, and must not schedule contradictory double notification unless user opts in. Never assume fasting start/end or hydration restriction: require user setup.

**Cross-midnight:** occurrence starting day D at 23:00 and ending D+1 at 01:00 occupies both calendar dates, but belongs to the starting-day template; conflict engine considers both date segments.

**Completion states:** planned, done, partly_done, skipped_intentionally, missed, cancelled. `missed` should be computed after grace period rather than automatically on exact due minute. Data for historical occurrences remains stable after rule edits.

**Overlap resolution:** detect overlap across work blocks, rest and spiritual events; warn with alternatives without silently moving user commitments. Notification quotas enforced; batch/degrade gracefully per Android/iOS OS limits. Reconcile scheduled OS notifications on reboot/timezone/permission changes where platform allows; show limitations and in-app agenda as fallback.

**Tests CAL-101…CAL-116:** last Fri-Sun on short/long months; last weekend across year; leap year; month on nonexistent day; cross-midnight; recurrence edit one vs series; overlap; missed grace period; travel timezone; alarm permission denied; reboot; DST when timezone changes; duplicate suppression; exception cancelled; old completion history; quiet hours.


## 32. COMMITMENT RECOVERY ENGINE — DETERMINISTIC RULES

This is the distinguishing product capability and must use explicit, explainable state transitions, **not unverified AI judgment**.

**Inputs:** `plannedAt`, `deadline`, `dueAt`, `estimatedMinutes`, `lastActionAt`, consecutive misses, deferrals, completion history, user workload capacity, pause/vacation mode, importance, quiet hours, user preferences. Never infer motivation or moral standing from device activity.

**Detection:** A commitment becomes `at_risk` when user-configured grace time elapses without action; `overdue` only when deadline/time has passed; `neglected` when planned next-action date is overdue by threshold (e.g. 3 days, configurable). No background process required to calculate status: recompute on application resume/open and periodically while foregrounded; use local reminders when allowed.

**User-facing recovery card:** Plain-language explanation (e.g., 'Reading was planned twice but no session was logged'), choices: Do 5 minutes now; Reschedule with date/time; Reduce frequency; Pause for a defined interval; Keep original plan; Archive goal. Never auto-archive or auto-downgrade. Respect spiritual practices—do not label prayer failure or offer spiritual grades.

**Anti-overwhelm logic:** At most three recovery cards prominently displayed per day, with a 'see all' panel. Do not create an unbounded queue of notifications. Optional weekly review proposes simplification after repeated misses. All suggestions are reversible and recorded with user consent.

**Tests REC-101…REC-110:** first miss, repeated misses, change of timezone, pause period, intentional skip, no notification permission, no activity for 60 days, same task under multiple views, archive/restore, no duplicate suggested action.


## 33. DATA SCHEMA — FIELD-LEVEL BASELINE

All tables are versioned and include migration tests. Primary keys use UUID (or a proven sortable UUID strategy), and all foreign keys are indexed/enforced. `created_at_utc`, `updated_at_utc`, `deleted_at_utc` and record `revision` apply to mutable records. Do not use a generic JSON blob in place of core relational constraints. Sensitive longform text and attachments remain encrypted at rest.

| Entity | Required fields beyond common metadata | Important constraints |
|---|---|---|
| OwnerProfile | locale, timezone, currency, week_start, notification_preferences | one active owner |
| Workspace | name, type, privacy_level, sort_order, archived | no broken task links |
| Goal | workspace_id, title, why, metric_type, target, active_state | nonnegative target where numeric |
| Task | workspace_id, title, details, status, importance, due_utc, scheduled_utc, estimate_minutes, next_action | title required; enum status |
| TaskDependency | task_id, depends_on_task_id | no self-dependency or cycles |
| Project | workspace_id, name, objective, status, start_on, target_on | preserve milestone history |
| Milestone | project_id, title, due_on, status, position | deterministic order |
| RoutineTemplate | owner_id, title, category, preferred_local_time, duration, timezone, minimum_target | duration nonnegative |
| RecurrenceRule | routine_id, pattern, interval, weekdays, month_policy, until, count | validated mutually compatible recurrence |
| OccurrenceException | routine_id, original_start, override_start, cancelled | unique original occurrence |
| Completion | routine_id, occurrence_key, state, actual_minutes, completed_at, notes | one final state per occurrence key |
| ReminderIntent | source_id, source_type, offset_minutes, channel, enabled, quiet_policy | schedule idempotently |
| JournalEntry | workspace_id, title, body_encrypted, visibility, entry_date | no public exposure |
| PrayerItem | title, notes, date_added, status, review_at | user-controlled state |
| FastPlan | recurrence_id, start_local, end_local, mode_label, safety_notes | overlaps allowed, no forced restrictions |
| Book | title, author, total_pages_nullable, format, status | page progress cannot exceed known total |
| StudySession | resource_id, duration_minutes, pages_start, pages_end, note_id | nonnegative duration |
| HabitLog | routine_id, occurrence_key, state, reason | unique occurrence |
| FinancialAccount | name, type, currency, opening_balance_minor, archived | currency immutable after postings |
| LedgerTransaction | type, status, effective_at, memo, original_transaction_id | immutable posting history |
| LedgerMovement | transaction_id, account_or_category_id, amount_minor, currency | transaction balances by currency |
| Budget | period, category_id, allocation_minor, rollover_policy | no duplicate active budget key |
| SavingsGoal | name, target_minor, deadline, linked_account_id | target positive |
| Liability | creditor_label, principal_minor, due_on, status | repayment links ledger |
| Attachment | encrypted_filename, mime_type, byte_size, content_hash, owner_record | hash verification on restore |
| Review | period, kind, completed_at, answers, summary | period uniqueness configurable |
| RecoveryAction | source_type, source_id, detection_reason, choice, chosen_at | preserve audit history |
| BackupManifest | schema_version, app_version, exported_at, counts, checksums | signed/authenticated encrypted container |

**Delete policies:** Financial postings never hard-delete through normal UI: void/reverse and retain audit; deleting parent projects leaves recoverable tasks with clear reassignment; journal soft delete with recovery duration; account archive blocks new posting but does not erase history; attachment removal updates ref counts; app-wide destroy permanently erases database and encryption keys only after explicit multi-step confirmation.


## 34. ERROR HANDLING, SECURITY AND PLATFORM CONSTRAINTS

**Security threats:** Lost phone, unattended unlocked app, exported unencrypted reports, screenshots in app switcher, malicious restore file, crafted attachment, local database exfiltration, rooted device and lost passphrase. Platform encryption must use a verified method: SQLCipher or equivalent for DB, authenticated encryption for attachments and backups, secure keystore-wrapped keys. Biometric authentication is convenience, not the only recovery mechanism. Document threat model and remaining limitations.

**Security controls:** Auto-lock on configurable idle period and background; optional hide-content-in-recents; never log PINs, journal bodies, passphrases, account details or backup keys; no telemetry by default; app permission request only at feature use; file picker import size/type controls and traversal protection; secure random salts/nonces; backups derive keys via memory-hard KDF; no plaintext temporary backup left behind; test failures and cancellation recovery.

**OS facts:** Android exact reminders may depend on Android version, exact-alarm permissions, battery management and notification permissions. iOS imposes local notification scheduling and background execution limits. External application usage monitoring is a separate, permission-restricted feature not guaranteed across platforms. Do not claim live background monitoring, enforced app blocking, or server-free cross-device sync unless actually implemented.

**Failure modes:** disk full while creating ledger entry; OS process killed during backup; corrupted attachment; backup from newer schema; notification disabled; timezone changed; device storage unavailable; passphrase rejected; lockout attempt; failed migration; user cancel midway. Fail safely, preserve original data, display clear recovery options and write no sensitive logs.

**Accessibility and localization:** Text scaling to 200%, touch targets ≥44x44 logical pts where feasible, high contrast, labeled icons, screen reader order, reduced motion, number format in NGN, timezone-aware week start, offline fonts. Navigation must be operable without dependence on gesture-only interactions.


## 35. END-TO-END USER SCENARIOS — REQUIRED BEFORE RELEASE

**E2E-01 Monday:** On Sunday user prepares outfits; on Monday 6 AM sees devotion and fasting intention; enters ₦1,500 transport and ₦3,000 food; reviews Bems priorities; at end of day logs reflection; closes and reopens offline; everything persists.

**E2E-02 Last weekend:** Last Friday–Sunday fast and weekly Friday fasting overlap once in calendar; completion and reports count each defined objective correctly without duplicate reminders.

**E2E-03 Neglected study:** User schedules a reading session, misses three planned sessions, opens app; app offers 'Do 5 minutes', 'Reschedule' and 'Reduce target'; user chooses smaller target; historical outcomes remain visible.

**E2E-04 Work separation:** Create Bems Group project with five milestones, three tasks and follow-up; create Henovate proposal task; switch contexts; personal finance reports do not include Bems work expense unless user explicitly records a separate personal expense.

**E2E-05 Cash transfer:** Enter ₦50,000 income to bank, ₦10,000 transfer to cash, ₦2,000 cash purchase, ₦500 partial refund, ₦1,000 transfer fee; balances and net category expense correct, cash transfers excluded from spending.

**E2E-06 No permission:** Deny notification permission; app still maintains all routines and displays due tasks; after grant, upcoming notifications reconcile without duplicates.

**E2E-07 Fresh phone:** Create multi-module records and encrypted backup; clear app/fresh install; choose restore; validate manifest and passphrase; verify counts, attachments, finances and recurrence exceptions match.

**E2E-08 Midnight:** Set 11 PM to 1 AM prayer, next day's 6 AM wake; conflict/sleep sustainability warning appears; neither event silently discarded; calendar accurately displays both dates.

**E2E-09 Large dataset:** Import/generate 10,000 tasks, 5,000 finance records, 1,000 journal entries as explicit test fixtures. All screens function, no fake numbers, search and pagination responsive.

**E2E-10 Privacy:** Lock app; notifications hide sensitive finance/journal descriptions when configured; app switcher masks private material; export warns about plaintext; deleting workspace respects attachments and ledger integrity.


## 36. DESIGN SYSTEM AND INDIVIDUAL SCREEN CONTRACTS

**Visual direction:** Modern, understated, mobile-first, light/dark, typography-led. Use sparse supportive accent color; no anxiety-inducing red badges for missed spiritual practice. Bottom navigation: Today, Plan, Tasks, Finance, More. Compact quick-add panel accessible from relevant contexts; no more than three tap steps to create a task or expense. No stock imagery required.

**Component library:** AppShell, WorkspaceSwitcher, TodayTimeline, CommitmentCard, TaskRow, RecurrenceEditor, AmountInput, MoneyAccountSelector, FilterBar, ReflectionEditor, TrendCard, ValidationMessage, NotificationPermissionExplainer, ConfirmSheet, OfflineStatusHint, PINEntry, BackupProgressSheet, EmptyState, RecoverySuggestionCard, WeeklyReviewWizard.

**Screen contract template (apply to every screen listed in §21):** `screen_id`, entry paths, feature permissions, query sources, UI sections, user inputs, validation, actions, database writes, navigation destinations, empty/error states, accessibility, analytics definitions, and test ids. Before implementation, AI builder shall create `screen_contracts.md` populating these fields for all screen IDs; any entry missing required actions blocks release.

**Representative detail — Create Expense:** Inputs amount (keypad), currency fixed by account, date/time, account, category, merchant/memo optional, receipt optional, repeating rule optional, split optional; Save disabled unless amount positive and account/category valid; save writes ledger transaction atomically and navigates to receipt/detail; balance and budget update on reopening. Cancel discards only after confirmation if edited. Duplicate candidate prompts review.

**Representative detail — Create Routine:** Title, category, rationale optional, target duration, minimum duration optional, preferred time, recurrence pattern, start/end, reminder lead, quiet-hour policy, workspace, active toggle; validation warns if recurrence misses all days or overlaps protected sleep; saving creates rule, not thousands of future rows. Editing offers 'this occurrence', 'this and future', 'entire series' with history preserved.

**Representative detail — Sunday Review:** View prior-week planned/done/deferred/missed by area, genuine expenditure by category, reading sessions, undone tasks across workspaces, wardrobe and cleaning preparation status. User decides next week's top goals and removes/reduces at least one impractical goal if overloaded. Review is saved as a historical record and not automatically modified by later task edits.


## 37. NON-FUNCTIONAL RELEASE TARGETS AND QUALITY BARS

**Performance SLOs:** Cold start to usable Today view under 3 seconds on midrange supported Android phone with typical dataset; ordinary list interactions under 200ms UI response; local task/expense save under 500ms for median case; heavy report under 3 seconds for 5,000 records, tested on named device and OS. Report actual measurements rather than falsely asserting pass.

**Reliability:** no data loss after force-close following successful write; schema migration backup/checkpoint before major version changes; idempotent reminders and recurring task generation; no duplicate ledger posting on double tap; offline core operations 100% supported.

**Testing layers:** Unit tests per domain rule, widget tests for form error states/navigation, repository/database migration tests, integration tests on Android emulator and physical device, optional iOS validation on macOS, backup restore testing on clean install. High-risk areas need property-based tests (currency balancing, recurrence occurrence uniqueness), fuzz malformed imports, and manual accessibility checks.

**App packaging:** Android application ID assigned at build time, minimal manifest permissions, adaptive icon, splash, signed build instructions, versioning, crash recovery documentation and local user guide. No production credentials in repository; `.env.example` only for optional future network services.


## 38. REQUIREMENTS COVERAGE CHECKLIST AND AI DELIVERY PROCESS

**Mandatory builder process:** (1) Parse requirements and freeze ID register. (2) Create data schema/migrations. (3) Implement full vertical slices per module (UI + domain + database + tests). (4) Test cross-module scenarios. (5) Validate offline mode, security, backup and restore. (6) Produce release artifact and honest requirement matrix. Never declare 'complete' after screens alone.

**Proof package:** `README.md`, `ARCHITECTURE.md`, `DATA_MODEL.md`, `MIGRATIONS.md`, `SCREEN_CONTRACTS.md`, `THREAT_MODEL.md`, `BACKUP_RESTORE.md`, `TEST_REPORT.md`, `KNOWN_LIMITATIONS.md`, `REQUIREMENTS_MATRIX.csv`, `USER_GUIDE.md`, reproducible Android build instructions and release APK if environment supports it.

**Hard blockers to release:** missing persistent CRUD, fake data, an unimplemented button, finance totals not balancing, destructive data corruption, broken recurrence, insecure backup, lack of actual restore test, mandatory network for core functions, silent schema failure, missing accessibility on main input journeys, deceptive completion claims.

**Explicit product assumptions:** single-owner private phone; NGN primary currency; Africa/Lagos default timezone; editable weekly/monthly fasting; no enforced spiritual or health judgments; Bems and Henovate separate workspaces; finances are personal only unless explicitly added; no company integrations or contact access without permission. All schedule durations are configurable.

**Instruction to coding AI:** 'Read this entire document, extract requirements into the matrix, and implement and test every required feature as working code. Break your internal work into verifiable implementation stages, but continue through them rather than equating stage one with the full product. Do not silently omit any screen, workflow, schema or edge case. Clearly flag features blocked by platform/environment limitations. Release only with reproducible build, full source and evidence.'
