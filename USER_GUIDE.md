# USER GUIDE & OPERATIONAL HANDBOOK
## Personal Life OS (v2.0 Engineering Edition)

Welcome to **Personal Life OS** — your private, calm, offline-first operating system designed to sustain habits, track personal commitments, manage independent professional workspaces, and maintain financial clarity without guilt or overwhelming streaks.

---

### 1. Getting Started

#### First Launch & Offline Onboarding
1. **Welcome Screen:** Tap **Get Started** to begin the offline configuration.
2. **Privacy Walkthrough:** Review the local storage guarantees. All your data is stored locally on this phone. Ensure you configure regular backups because no central cloud server holds your information.
3. **Owner Profile:** Configure your name, default currency (₦ Nigerian Naira default), timezone (`Africa/Lagos`), and week start (Monday).
4. **Sleep & Aspirations:** Set your target sleep window (e.g. 11:00 PM to 6:00 AM). If you configure less than 5 hours of rest opportunity, the app presents a gentle health advisory.
5. **Workspaces:** Choose your active workspaces:
   - **Personal:** Private life, spiritual devotions, household chores, wardrobe, personal finances.
   - **Bems Group:** Chief Operating Officer (COO) responsibilities, deliverables, meetings, delegated follow-ups.
   - **Henovate:** Founder initiatives, product roadmap, client proposals, growth milestones.

---

### 2. Daily Core Workflows

#### Today Dashboard (`SCR-06`)
- **Top 3 Priorities:** Each morning, select up to three high-impact tasks. You can mark them completed with a single tap.
- **Daily Timeline:** View time blocks for prayer, work, exercise, and chores. Cross-midnight blocks (such as 11:00 PM to 1:00 AM) are properly calculated.
- **Quick Expense:** Tap the ₦ button to log an expense in under 3 taps.
- **Privacy Masking:** Tap the eye icon in the top header to mask financial figures (`₦ ••••••`) and confidential notes when viewing in public.

#### Commitment Recovery Engine (`SCR-17`)
When motivation drops or unforeseen life events interrupt your routines:
- The app displays **at most three recovery cards** per day.
- Choose to:
  - **Do 5 minutes now:** A tiny, achievable step to rebuild momentum.
  - **Reschedule:** Move the task to an achievable date without feeling guilty.
  - **Simplify target:** Reduce the daily target (e.g., from 30 pages to 10 pages).
  - **Pause:** Temporarily put a habit on hold for 7 days.

---

### 3. Spiritual Practice & Health

#### Fasting Planner (`SCR-27`)
- Supports recurring Monday and Friday fasts, plus the monthly 3-day last-weekend fast (Friday through Sunday).
- **Deduplication:** When the monthly 3-day fast occurs, the Friday is counted once against your regular Friday habit.
- **Health & Hydration:** Gentle health reminders advise safe hydration without guilt.

#### Bible Study & Prayer Journal (`SCR-24`, `SCR-25`)
- Record scripture references, personal study observations, and prayer themes.
- Sensitive spiritual notes are excluded from lock screen notifications by default.

---

### 4. Financial Control & Ledger

#### Double-Entry Ledger Principles
- All amounts are computed in integer minor units (kobo) for mathematical accuracy.
- **Transfers between accounts** (e.g., Bank to Cash) do not count as expenses or income.
- **Savings contributions** build your savings goal progress without inflating monthly spending figures.
- **Duplicate Detection:** If you record a transaction with the same amount and account within 24 hours, the app asks you to confirm rather than creating an accidental duplicate.

---

### 5. Backup & Data Recovery

#### Creating a Backup (`SCR-57`)
1. Open **Settings** -> **Backup & Restore**.
2. Tap **Create Encrypted Backup**.
3. Enter a secure passphrase. **Remember this passphrase** — because the backup is strongly encrypted with Argon2id + AES-GCM, it cannot be recovered if forgotten.
4. Save the `.plos` file to your device, an SD card, or your personal cloud storage (Google Drive, iCloud, etc.) via the file picker.

#### Restoring on a New Device
1. On the welcome screen or in Settings, select **Restore Backup**.
2. Select your `.plos` file and enter your passphrase.
3. The app verifies the cryptographic signature and checks the database integrity in an isolated sandbox before safely loading your records.
