# KNOWN LIMITATIONS & PLATFORM TRUTHFULNESS REPORT
## Personal Life OS (v2.0 Engineering Edition)

In strict compliance with PRD Section 0, Section 1.4, Section 22, and Section 34, this document explicitly lists capabilities that cannot be automated offline or are bounded by mobile operating system constraints. The software presents zero fake claims or mock indicators for these boundaries.

### 1. Bank & Financial Institution Connectivity
- **PRD Non-Goal §1.4 & §11.1:** There is **no automated bank feed, scraping, or real-time account transfer integration** in V1.
- **Truthful Alternative:** Personal Life OS provides a manual, double-entry ledger with multi-account support, fast <=3 tap expense capture, receipt attachments, and CSV import/export. Bank credentials are never requested or stored.

### 2. Operating System App Usage Monitoring & Blocking
- **PRD Boundary §13.3 & §34:** iOS sandboxing does not permit third-party applications to monitor other installed apps' active screen time or forcibly block app launches. Android requires explicit `PACKAGE_USAGE_STATS` permission.
- **Truthful Alternative:** Digital discipline operates primarily via voluntary, self-reported distraction logs, scheduled quiet hours, and intentional focus timer sessions. The app displays a clear OS privacy disclosure note (`SCR-47`) rather than claiming background surveillance capabilities.

### 3. Native Background Notifications & Doze Mode
- **PRD Constraint §16.5 & §16.6:** Mobile operating systems (Android Doze mode, iOS notification budgets, battery optimization, or user denial of notification permissions) can delay or suppress scheduled alerts.
- **Truthful Alternative:** The application maintains a persistent, in-app **Activity & Notification Inbox** (`SCR-55`). Reminders are never dropped or lost from user visibility even when OS alert permissions are completely denied (`BR-11`).

### 4. Copyrighted Scripture Text
- **PRD Boundary §8.2 & §27:** Bundling full copyrighted Bible translations without explicit publisher licensing violates distribution policies.
- **Truthful Alternative:** The Bible Study module (`SCR-25`) implements an offline passage reference planner, study observation questions, and personal reflections. Users may paste, type, or import text from their personal licensed copies.

### 5. Medical Diagnoses & Spiritual Worth Scoring
- **PRD Directives §1.4, §8.6, §14.1, §17.6:**
  - Sleep and exercise tracking are voluntary wellbeing journals and **never offer medical diagnoses** or prescriptive clinical advice.
  - Spiritual devotion (prayer, Bible study, fasting) is presented via gentle continuity tracking. The system features **zero streak-breaking shame, gamified leaderboards, or automated moral assessments**.
