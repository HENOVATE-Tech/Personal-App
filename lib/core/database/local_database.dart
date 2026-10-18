import 'dart:async';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import 'schema_models.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal() {
    _initDefaultData();
  }

  final _uuid = const Uuid();

  // Storage In-Memory Cache (backed by persistent JSON/SQLite sync)
  UserProfile _userProfile = const UserProfile(id: 'owner-default');
  final List<Workspace> _workspaces = [];
  final List<Task> _tasks = [];
  final List<TaskChecklistItem> _taskChecklistItems = [];
  final List<CalendarEvent> _calendarEvents = [];
  final List<RoutineTemplate> _routineTemplates = [];
  final List<FastPlan> _fastPlans = [];
  final List<CareChecklistItem> _careChecklistItems = [];
  final List<Chore> _chores = [];
  final List<OutfitPlan> _outfitPlans = [];
  final List<FinancialAccount> _financialAccounts = [];
  final List<FinancialCategory> _financialCategories = [];
  final List<LedgerTransaction> _ledgerTransactions = [];
  final List<LedgerMovement> _ledgerMovements = [];
  final List<Budget> _budgets = [];
  final List<Bill> _bills = [];
  final List<SavingsGoal> _savingsGoals = [];
  final List<Book> _books = [];
  final List<SleepLog> _sleepLogs = [];
  final List<FollowUp> _followUps = [];
  final List<Project> _projects = [];
  final List<Milestone> _milestones = [];
  final List<JournalEntry> _journalEntries = [];
  final List<PrayerSession> _prayerSessions = [];
  final List<RecoveryAction> _recoveryActions = [];
  final List<InAppNotification> _notifications = [];
  final List<ReviewEntry> _reviews = [];

  // Stream controllers for reactivity
  final _changeStreamController = StreamController<void>.broadcast();
  Stream<void> get changes => _changeStreamController.stream;

  void _notify() {
    _changeStreamController.add(null);
  }

  // --- Initial Data Seed ---
  void _initDefaultData() {
    // 1. Workspaces
    _workspaces.addAll([
      const Workspace(
        id: AppConstants.workspacePersonalId,
        name: 'Personal',
        type: 'personal',
        colorValue: 0xFF3B82F6,
        isDefault: true,
      ),
      const Workspace(
        id: AppConstants.workspaceBemsId,
        name: 'Bems Group',
        type: 'professional',
        colorValue: 0xFF10B981,
      ),
      const Workspace(
        id: AppConstants.workspaceHenovateId,
        name: 'Henovate',
        type: 'professional',
        colorValue: 0xFF8B5CF6,
      ),
    ]);

    // 2. Financial Accounts
    _financialAccounts.addAll([
      const FinancialAccount(
        id: 'acc-cash',
        name: 'Cash / Physical Wallet',
        accountType: AccountType.cash,
        openingBalanceKobo: 2500000, // ₦25,000.00
        balanceKobo: 2500000,
      ),
      const FinancialAccount(
        id: 'acc-gtb',
        name: 'Guaranty Trust Bank (GTB)',
        accountType: AccountType.bank,
        openingBalanceKobo: 35000000, // ₦350,000.00
        balanceKobo: 35000000,
      ),
      const FinancialAccount(
        id: 'acc-savings',
        name: 'High-Yield Savings',
        accountType: AccountType.savings,
        openingBalanceKobo: 120000000, // ₦1,200,000.00
        balanceKobo: 120000000,
      ),
    ]);

    // 3. Financial Categories
    _financialCategories.addAll([
      const FinancialCategory(id: 'cat-food', name: 'Food & Groceries', type: 'expense', iconName: 'restaurant', colorValue: 0xFFF59E0B),
      const FinancialCategory(id: 'cat-transport', name: 'Transport & Fuel', type: 'expense', iconName: 'directions_car', colorValue: 0xFF3B82F6),
      const FinancialCategory(id: 'cat-utilities', name: 'Utilities & Internet', type: 'expense', iconName: 'bolt', colorValue: 0xFF10B981),
      const FinancialCategory(id: 'cat-giving', name: 'Giving & Tithes', type: 'expense', iconName: 'volunteer_activism', colorValue: 0xFFEC4899),
      const FinancialCategory(id: 'cat-salary', name: 'Salary & Earnings', type: 'income', iconName: 'payments', colorValue: 0xFF059669),
      const FinancialCategory(id: 'cat-consulting', name: 'Henovate Consulting', type: 'income', iconName: 'business_center', colorValue: 0xFF7C3AED),
    ]);

    // 4. Default Routine Templates
    _routineTemplates.addAll([
      const RoutineTemplate(
        id: 'rt-wake',
        title: 'Morning Awakening & Stillness',
        category: 'Spiritual',
        preferredTimeLocal: '06:00',
        targetDurationMins: 30,
      ),
      const RoutineTemplate(
        id: 'rt-devotion',
        title: 'Morning Meditation & Prayer',
        category: 'Spiritual',
        preferredTimeLocal: '06:30',
        targetDurationMins: 90,
      ),
      const RoutineTemplate(
        id: 'rt-bible-study',
        title: 'Evening Bible Study & Exegesis',
        category: 'Spiritual',
        preferredTimeLocal: '21:00',
        targetDurationMins: 60,
      ),
      const RoutineTemplate(
        id: 'rt-night-prayer',
        title: 'Night Prayer & Vigil',
        category: 'Spiritual',
        preferredTimeLocal: '23:00',
        targetDurationMins: 120, // 23:00 to 01:00 cross-midnight
      ),
    ]);

    // 5. Default Care Checklist
    _careChecklistItems.addAll([
      const CareChecklistItem(id: 'care-1', title: 'Morning Dental Hygiene & Shower', period: 'morning'),
      const CareChecklistItem(id: 'care-2', title: 'Make Bed & Desk Tidying', period: 'morning'),
      const CareChecklistItem(id: 'care-3', title: 'Hydration Target (2L Water)', period: 'daily'),
      const CareChecklistItem(id: 'care-4', title: 'Evening Dental Care', period: 'evening'),
    ]);

    // 6. Default Chores
    _chores.addAll([
      const Chore(
        id: 'chore-1',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Weekend Laundry & Pressing',
        frequency: 'weekly',
        estimatedMins: 90,
      ),
      const Chore(
        id: 'chore-2',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Deep Bedroom & Bathroom Clean',
        frequency: 'weekly',
        estimatedMins: 60,
      ),
    ]);

    // 7. Seed Tasks
    final now = DateTime.now();
    _tasks.addAll([
      Task(
        id: 'task-1',
        workspaceId: AppConstants.workspacePersonalId,
        title: 'Prepare Weekday Outfits (Mon–Sun)',
        nextAction: 'Sort laundry and hang 5 pressed outfits for the week',
        importance: TaskImportance.high,
        isTopPriority: true,
        scheduledDate: DateTime(now.year, now.month, now.day),
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      Task(
        id: 'task-2',
        workspaceId: AppConstants.workspaceBemsId,
        title: 'Q4 Operations Bottleneck Review',
        nextAction: 'Review department delivery milestones with team leads',
        importance: TaskImportance.urgent,
        isTopPriority: true,
        scheduledDate: DateTime(now.year, now.month, now.day),
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Task(
        id: 'task-3',
        workspaceId: AppConstants.workspaceHenovateId,
        title: 'Client Discovery Architecture Draft',
        nextAction: 'Finalize offline architecture spec for enterprise prospect',
        importance: TaskImportance.high,
        isTopPriority: true,
        scheduledDate: DateTime(now.year, now.month, now.day),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  // --- Profile & Preferences ---
  UserProfile get userProfile => _userProfile;
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    _notify();
  }

  // --- Workspaces ---
  List<Workspace> getWorkspaces() => List.unmodifiable(_workspaces);
  Workspace? getWorkspaceById(String id) =>
      _workspaces.cast<Workspace?>().firstWhere((w) => w?.id == id, orElse: () => null);

  // --- Tasks ---
  List<Task> getTasks({String? workspaceId}) {
    if (workspaceId == null || workspaceId.isEmpty) {
      return List.unmodifiable(_tasks);
    }
    return _tasks.where((t) => t.workspaceId == workspaceId).toList();
  }

  Task? getTaskById(String id) =>
      _tasks.cast<Task?>().firstWhere((t) => t?.id == id, orElse: () => null);

  void upsertTask(Task task) {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _tasks[idx] = task;
    } else {
      _tasks.add(task);
    }
    _notify();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _taskChecklistItems.removeWhere((c) => c.taskId == id);
    _notify();
  }

  void toggleTaskComplete(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      final t = _tasks[idx];
      final isDone = t.status == TaskStatus.completed;
      _tasks[idx] = t.copyWith(
        status: isDone ? TaskStatus.inProgress : TaskStatus.completed,
        completedAt: isDone ? null : DateTime.now(),
      );
      _notify();
    }
  }

  // --- Routines ---
  List<RoutineTemplate> getRoutineTemplates() => List.unmodifiable(_routineTemplates);

  void toggleRoutineCompleted(String id) {
    final idx = _routineTemplates.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _routineTemplates[idx] = _routineTemplates[idx].copyWith(
        isCompletedToday: !_routineTemplates[idx].isCompletedToday,
      );
      _notify();
    }
  }

  // --- Care Checklist ---
  List<CareChecklistItem> getCareChecklist() => List.unmodifiable(_careChecklistItems);
  void toggleCareItem(String id) {
    final idx = _careChecklistItems.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _careChecklistItems[idx] = _careChecklistItems[idx].copyWith(
        isCompleted: !_careChecklistItems[idx].isCompleted,
      );
      _notify();
    }
  }

  // --- Chores ---
  List<Chore> getChores({String? workspaceId}) {
    if (workspaceId == null || workspaceId.isEmpty) {
      return List.unmodifiable(_chores);
    }
    return _chores.where((c) => c.workspaceId == workspaceId).toList();
  }

  void toggleChoreComplete(String id) {
    final idx = _chores.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final isCompleted = !_chores[idx].isCompleted;
      _chores[idx] = _chores[idx].copyWith(
        isCompleted: isCompleted,
        lastCompletedAt: isCompleted ? DateTime.now() : null,
      );
      _notify();
    }
  }

  // --- Financial Ledger Engine (BR-06 & Double Entry) ---
  List<FinancialAccount> getFinancialAccounts() => List.unmodifiable(_financialAccounts);
  List<FinancialCategory> getFinancialCategories() => List.unmodifiable(_financialCategories);
  List<LedgerTransaction> getLedgerTransactions() => List.unmodifiable(_ledgerTransactions);

  /// Executes an atomic double-entry transaction.
  /// Enforces BR-06:
  /// - Movement sum MUST equal 0.
  /// - Asset accounts update their real-time posted balance.
  /// - Category allocations update for reporting without affecting transfer neutrality.
  void postTransaction({
    required TransactionType type,
    required DateTime effectiveAt,
    required String memo,
    String? workspaceId,
    required List<LedgerMovement> movements,
  }) {
    // 1. Verify Balanced Journal: Sum(amountKobo) == 0
    final sum = movements.fold<int>(0, (prev, m) => prev + m.amountKobo);
    if (sum != 0) {
      throw ArgumentError('Unbalanced ledger journal: Sum of movements is $sum (must equal 0)');
    }

    final txId = _uuid.v4();
    final tx = LedgerTransaction(
      id: txId,
      type: type,
      effectiveAt: effectiveAt,
      memo: memo,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
    );

    // 2. Persist transaction and movements
    _ledgerTransactions.insert(0, tx);
    for (final m in movements) {
      _ledgerMovements.add(m);

      // 3. Update account balance if movement targets an account
      if (m.accountId != null) {
        final accIdx = _financialAccounts.indexWhere((a) => a.id == m.accountId);
        if (accIdx >= 0) {
          final acc = _financialAccounts[accIdx];
          _financialAccounts[accIdx] = acc.copyWith(
            balanceKobo: acc.balanceKobo + m.amountKobo,
          );
        }
      }
    }

    _notify();
  }

  // --- Recovery Actions ---
  List<RecoveryAction> getActiveRecoveryActions() {
    return _recoveryActions.where((a) => a.actionChosen == null).take(AppConstants.maxActiveRecoveryCards).toList();
  }

  void addRecoveryAction(RecoveryAction action) {
    _recoveryActions.add(action);
    _notify();
  }

  void resolveRecoveryAction(String id, String choice) {
    final idx = _recoveryActions.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _recoveryActions[idx] = _recoveryActions[idx].copyWith(actionChosen: choice);
      _notify();
    }
  }

  // --- Notifications Inbox ---
  List<InAppNotification> getNotifications() => List.unmodifiable(_notifications);

  void addNotification(InAppNotification notification) {
    _notifications.insert(0, notification);
    _notify();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _notify();
    }
  }

  // --- Reviews ---
  List<ReviewEntry> getReviews() => List.unmodifiable(_reviews);
  void saveReview(ReviewEntry review) {
    _reviews.insert(0, review);
    _notify();
  }

  // --- Fasting Plans ---
  List<FastPlan> getFastPlans() => List.unmodifiable(_fastPlans);
  void addFastPlan(FastPlan plan) {
    _fastPlans.add(plan);
    _notify();
  }

  // --- Outfit Plans ---
  List<OutfitPlan> getOutfitPlans() => List.unmodifiable(_outfitPlans);
  void upsertOutfitPlan(OutfitPlan plan) {
    final idx = _outfitPlans.indexWhere((p) => p.dayOfWeek == plan.dayOfWeek);
    if (idx >= 0) {
      _outfitPlans[idx] = plan;
    } else {
      _outfitPlans.add(plan);
    }
    _notify();
  }

  // --- Books ---
  List<Book> getBooks() => List.unmodifiable(_books);
  void upsertBook(Book book) {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx >= 0) {
      _books[idx] = book;
    } else {
      _books.add(book);
    }
    _notify();
  }

  // --- Sleep Logs ---
  List<SleepLog> getSleepLogs() => List.unmodifiable(_sleepLogs);
  void addSleepLog(SleepLog log) {
    _sleepLogs.insert(0, log);
    _notify();
  }

  // --- Follow Ups ---
  List<FollowUp> getFollowUps({String? workspaceId}) {
    if (workspaceId == null || workspaceId.isEmpty) {
      return List.unmodifiable(_followUps);
    }
    return _followUps.where((f) => f.workspaceId == workspaceId).toList();
  }

  void addFollowUp(FollowUp followUp) {
    _followUps.add(followUp);
    _notify();
  }

  // --- Journal Entries ---
  List<JournalEntry> getJournalEntries({String? workspaceId}) {
    if (workspaceId == null || workspaceId.isEmpty) {
      return List.unmodifiable(_journalEntries);
    }
    return _journalEntries.where((j) => j.workspaceId == workspaceId).toList();
  }

  void addJournalEntry(JournalEntry entry) {
    _journalEntries.insert(0, entry);
    _notify();
  }

  // --- Prayer Sessions ---
  List<PrayerSession> getPrayerSessions() => List.unmodifiable(_prayerSessions);
  void addPrayerSession(PrayerSession session) {
    _prayerSessions.insert(0, session);
    _notify();
  }

  // --- Wipe All Data (Atomic Confirmation) ---
  void wipeAllData() {
    _tasks.clear();
    _taskChecklistItems.clear();
    _calendarEvents.clear();
    _routineTemplates.clear();
    _fastPlans.clear();
    _careChecklistItems.clear();
    _chores.clear();
    _outfitPlans.clear();
    _financialAccounts.clear();
    _financialCategories.clear();
    _ledgerTransactions.clear();
    _ledgerMovements.clear();
    _budgets.clear();
    _bills.clear();
    _savingsGoals.clear();
    _books.clear();
    _sleepLogs.clear();
    _followUps.clear();
    _projects.clear();
    _milestones.clear();
    _journalEntries.clear();
    _prayerSessions.clear();
    _recoveryActions.clear();
    _notifications.clear();
    _reviews.clear();
    _initDefaultData();
    _notify();
  }
}
