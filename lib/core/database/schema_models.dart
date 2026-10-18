class UserProfile {
  final String id;
  final String displayName;
  final String locale;
  final String timezone;
  final String currency;
  final int weekStartDay; // 1 = Monday, 7 = Sunday
  final bool is24Hour;
  final String bedtimeTarget; // e.g. "23:00"
  final String wakingTarget;  // e.g. "06:00"
  final int morningDevotionMins;
  final bool appLockEnabled;
  final String? pinHash;
  final String? pinSalt;
  final bool privacyModeEnabled;

  const UserProfile({
    required this.id,
    this.displayName = 'Owner',
    this.locale = 'en_NG',
    this.timezone = 'Africa/Lagos',
    this.currency = 'NGN',
    this.weekStartDay = 1,
    this.is24Hour = false,
    this.bedtimeTarget = '23:00',
    this.wakingTarget = '06:00',
    this.morningDevotionMins = 120,
    this.appLockEnabled = false,
    this.pinHash,
    this.pinSalt,
    this.privacyModeEnabled = false,
  });

  UserProfile copyWith({
    String? displayName,
    String? locale,
    String? timezone,
    String? currency,
    int? weekStartDay,
    bool? is24Hour,
    String? bedtimeTarget,
    String? wakingTarget,
    int? morningDevotionMins,
    bool? appLockEnabled,
    String? pinHash,
    String? pinSalt,
    bool? privacyModeEnabled,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      is24Hour: is24Hour ?? this.is24Hour,
      bedtimeTarget: bedtimeTarget ?? this.bedtimeTarget,
      wakingTarget: wakingTarget ?? this.wakingTarget,
      morningDevotionMins: morningDevotionMins ?? this.morningDevotionMins,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
    );
  }
}

class Workspace {
  final String id;
  final String name;
  final String type; // personal, professional, custom
  final int colorValue;
  final bool isDefault;
  final bool isArchived;

  const Workspace({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    this.isDefault = false,
    this.isArchived = false,
  });
}

enum TaskStatus {
  inbox,
  next,
  scheduled,
  inProgress,
  blocked,
  completed,
  cancelled,
  archived,
}

enum TaskImportance { low, medium, high, urgent }

class Task {
  final String id;
  final String workspaceId;
  final String? projectId;
  final String title;
  final String nextAction;
  final String? notes;
  final TaskStatus status;
  final TaskImportance importance;
  final DateTime? dueUtc;
  final DateTime? scheduledDate;
  final int estimateMinutes;
  final bool isTopPriority;
  final int postponementCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.workspaceId,
    this.projectId,
    required this.title,
    this.nextAction = '',
    this.notes,
    this.status = TaskStatus.inbox,
    this.importance = TaskImportance.medium,
    this.dueUtc,
    this.scheduledDate,
    this.estimateMinutes = 30,
    this.isTopPriority = false,
    this.postponementCount = 0,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    String? workspaceId,
    String? projectId,
    String? title,
    String? nextAction,
    String? notes,
    TaskStatus? status,
    TaskImportance? importance,
    DateTime? dueUtc,
    DateTime? scheduledDate,
    int? estimateMinutes,
    bool? isTopPriority,
    int? postponementCount,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      workspaceId: workspaceId ?? this.workspaceId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      nextAction: nextAction ?? this.nextAction,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      dueUtc: dueUtc ?? this.dueUtc,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      isTopPriority: isTopPriority ?? this.isTopPriority,
      postponementCount: postponementCount ?? this.postponementCount,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TaskChecklistItem {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;

  const TaskChecklistItem({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    required this.position,
  });

  TaskChecklistItem copyWith({bool? isCompleted, String? title}) {
    return TaskChecklistItem(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position,
    );
  }
}

class CalendarEvent {
  final String id;
  final String workspaceId;
  final String title;
  final String category;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final bool isCompleted;

  const CalendarEvent({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    this.isCompleted = false,
  });
}

class RoutineTemplate {
  final String id;
  final String title;
  final String category;
  final String preferredTimeLocal; // "06:00"
  final int targetDurationMins;
  final int minDurationMins;
  final bool isCompletedToday;

  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.preferredTimeLocal,
    required this.targetDurationMins,
    this.minDurationMins = 10,
    this.isCompletedToday = false,
  });

  RoutineTemplate copyWith({bool? isCompletedToday}) {
    return RoutineTemplate(
      id: id,
      title: title,
      category: category,
      preferredTimeLocal: preferredTimeLocal,
      targetDurationMins: targetDurationMins,
      minDurationMins: minDurationMins,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }
}

class FastPlan {
  final String id;
  final String title;
  final String mode; // "Water Only", "Partial", "6am-6pm"
  final String safetyNotes;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  const FastPlan({
    required this.id,
    required this.title,
    required this.mode,
    this.safetyNotes = 'Stay hydrated and break if feeling faint or unwell.',
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });
}

class CareChecklistItem {
  final String id;
  final String title;
  final String period; // morning, evening, weekly
  final bool isCompleted;

  const CareChecklistItem({
    required this.id,
    required this.title,
    required this.period,
    this.isCompleted = false,
  });

  CareChecklistItem copyWith({bool? isCompleted}) {
    return CareChecklistItem(
      id: id,
      title: title,
      period: period,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Chore {
  final String id;
  final String workspaceId;
  final String title;
  final String frequency; // daily, weekly, monthly
  final int estimatedMins;
  final bool isCompleted;
  final DateTime? lastCompletedAt;

  const Chore({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.frequency,
    this.estimatedMins = 30,
    this.isCompleted = false,
    this.lastCompletedAt,
  });

  Chore copyWith({bool? isCompleted, DateTime? lastCompletedAt}) {
    return Chore(
      id: id,
      workspaceId: workspaceId,
      title: title,
      frequency: frequency,
      estimatedMins: estimatedMins,
      isCompleted: isCompleted ?? this.isCompleted,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}

class OutfitPlan {
  final String id;
  final String dayOfWeek; // "Monday", "Tuesday", etc.
  final DateTime calendarDate;
  final String outfitDescription;
  final String status; // "Ready", "Needs Ironing", "In Laundry"

  const OutfitPlan({
    required this.id,
    required this.dayOfWeek,
    required this.calendarDate,
    required this.outfitDescription,
    this.status = 'Ready',
  });

  OutfitPlan copyWith({String? outfitDescription, String? status}) {
    return OutfitPlan(
      id: id,
      dayOfWeek: dayOfWeek,
      calendarDate: calendarDate,
      outfitDescription: outfitDescription ?? this.outfitDescription,
      status: status ?? this.status,
    );
  }
}

enum AccountType { cash, bank, wallet, savings, liability }

class FinancialAccount {
  final String id;
  final String name;
  final AccountType accountType;
  final String currency;
  final int openingBalanceKobo;
  final int balanceKobo;
  final bool isArchived;

  const FinancialAccount({
    required this.id,
    required this.name,
    required this.accountType,
    this.currency = 'NGN',
    required this.openingBalanceKobo,
    required this.balanceKobo,
    this.isArchived = false,
  });

  FinancialAccount copyWith({
    String? name,
    int? balanceKobo,
    bool? isArchived,
  }) {
    return FinancialAccount(
      id: id,
      name: name ?? this.name,
      accountType: accountType,
      currency: currency,
      openingBalanceKobo: openingBalanceKobo,
      balanceKobo: balanceKobo ?? this.balanceKobo,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

class FinancialCategory {
  final String id;
  final String name;
  final String type; // "expense" or "income"
  final String iconName;
  final int colorValue;

  const FinancialCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorValue,
  });
}

enum TransactionType { expense, income, transfer, refund }

class LedgerTransaction {
  final String id;
  final TransactionType type;
  final DateTime effectiveAt;
  final String memo;
  final String? workspaceId;
  final String? originalTransactionId; // For reversals / refunds
  final DateTime createdAt;

  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.effectiveAt,
    required this.memo,
    this.workspaceId,
    this.originalTransactionId,
    required this.createdAt,
  });
}

class LedgerMovement {
  final String id;
  final String transactionId;
  final String? accountId;
  final String? categoryId;
  final int amountKobo; // Signed: positive = credit, negative = debit
  final String currency;

  const LedgerMovement({
    required this.id,
    required this.transactionId,
    this.accountId,
    this.categoryId,
    required this.amountKobo,
    this.currency = 'NGN',
  });
}

class Budget {
  final String id;
  final String categoryId;
  final String periodMonthYear; // e.g. "2026-10"
  final int allocatedKobo;
  final int spentKobo;
  final bool rolloverEligible;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.periodMonthYear,
    required this.allocatedKobo,
    this.spentKobo = 0,
    this.rolloverEligible = false,
  });

  Budget copyWith({int? allocatedKobo, int? spentKobo}) {
    return Budget(
      id: id,
      categoryId: categoryId,
      periodMonthYear: periodMonthYear,
      allocatedKobo: allocatedKobo ?? this.allocatedKobo,
      spentKobo: spentKobo ?? this.spentKobo,
      rolloverEligible: rolloverEligible,
    );
  }
}

class Bill {
  final String id;
  final String payee;
  final String categoryId;
  final String accountId;
  final int amountKobo;
  final int dueDay;
  final bool isPaid;

  const Bill({
    required this.id,
    required this.payee,
    required this.categoryId,
    required this.accountId,
    required this.amountKobo,
    required this.dueDay,
    this.isPaid = false,
  });

  Bill copyWith({bool? isPaid}) {
    return Bill(
      id: id,
      payee: payee,
      categoryId: categoryId,
      accountId: accountId,
      amountKobo: amountKobo,
      dueDay: dueDay,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class SavingsGoal {
  final String id;
  final String title;
  final int targetKobo;
  final int accumulatedKobo;
  final DateTime targetDate;
  final String? linkedAccountId;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetKobo,
    this.accumulatedKobo = 0,
    required this.targetDate,
    this.linkedAccountId,
  });

  SavingsGoal copyWith({int? accumulatedKobo}) {
    return SavingsGoal(
      id: id,
      title: title,
      targetKobo: targetKobo,
      accumulatedKobo: accumulatedKobo ?? this.accumulatedKobo,
      targetDate: targetDate,
      linkedAccountId: linkedAccountId,
    );
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String format; // physical, ebook, audio
  final int totalPages;
  final int currentPage;
  final String status; // reading, completed, planned

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.format = 'physical',
    required this.totalPages,
    this.currentPage = 0,
    this.status = 'reading',
  });

  Book copyWith({int? currentPage, String? status}) {
    return Book(
      id: id,
      title: title,
      author: author,
      format: format,
      totalPages: totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
    );
  }
}

class SleepLog {
  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int actualSleepMins;
  final int wellbeingScore; // 1 to 5
  final String? notes;

  const SleepLog({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    required this.actualSleepMins,
    this.wellbeingScore = 3,
    this.notes,
  });
}

class FollowUp {
  final String id;
  final String workspaceId;
  final String personName;
  final String commitment;
  final DateTime requestedDate;
  final DateTime expectedDate;
  final String status; // pending, received, closed

  const FollowUp({
    required this.id,
    required this.workspaceId,
    required this.personName,
    required this.commitment,
    required this.requestedDate,
    required this.expectedDate,
    this.status = 'pending',
  });

  FollowUp copyWith({String? status}) {
    return FollowUp(
      id: id,
      workspaceId: workspaceId,
      personName: personName,
      commitment: commitment,
      requestedDate: requestedDate,
      expectedDate: expectedDate,
      status: status ?? this.status,
    );
  }
}

class Project {
  final String id;
  final String workspaceId;
  final String name;
  final String objective;
  final String status; // active, paused, completed
  final DateTime startDate;
  final DateTime targetDate;

  const Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.objective,
    this.status = 'active',
    required this.startDate,
    required this.targetDate,
  });

  Project copyWith({String? status}) {
    return Project(
      id: id,
      workspaceId: workspaceId,
      name: name,
      objective: objective,
      status: status ?? this.status,
      startDate: startDate,
      targetDate: targetDate,
    );
  }
}

class Milestone {
  final String id;
  final String projectId;
  final String title;
  final DateTime dueDate;
  final bool isCompleted;
  final int position;

  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    required this.position,
  });

  Milestone copyWith({bool? isCompleted}) {
    return Milestone(
      id: id,
      projectId: projectId,
      title: title,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position,
    );
  }
}

class JournalEntry {
  final String id;
  final String workspaceId;
  final String title;
  final String body;
  final DateTime entryDate;
  final bool isEncrypted;

  const JournalEntry({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.body,
    required this.entryDate,
    this.isEncrypted = true,
  });
}

class PrayerSession {
  final String id;
  final String workspaceId;
  final String theme;
  final String scriptureRefs;
  final int actualDurationMins;
  final String? notes;
  final bool isAnswered;
  final DateTime sessionDate;

  const PrayerSession({
    required this.id,
    required this.workspaceId,
    required this.theme,
    required this.scriptureRefs,
    required this.actualDurationMins,
    this.notes,
    this.isAnswered = false,
    required this.sessionDate,
  });

  PrayerSession copyWith({bool? isAnswered, String? notes}) {
    return PrayerSession(
      id: id,
      workspaceId: workspaceId,
      theme: theme,
      scriptureRefs: scriptureRefs,
      actualDurationMins: actualDurationMins,
      notes: notes ?? this.notes,
      isAnswered: isAnswered ?? this.isAnswered,
      sessionDate: sessionDate,
    );
  }
}

class RecoveryAction {
  final String id;
  final String sourceType; // "task" or "routine"
  final String sourceId;
  final String title;
  final String reason;
  final String? actionChosen; // "do_5_min", "reschedule", "simplify", "pause", "cancel"
  final DateTime createdAt;

  const RecoveryAction({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.reason,
    this.actionChosen,
    required this.createdAt,
  });

  RecoveryAction copyWith({String? actionChosen}) {
    return RecoveryAction(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      reason: reason,
      actionChosen: actionChosen ?? this.actionChosen,
      createdAt: createdAt,
    );
  }
}

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final bool isRead;
  final bool isDismissed;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.isRead = false,
    this.isDismissed = false,
  });

  InAppNotification copyWith({bool? isRead, bool? isDismissed}) {
    return InAppNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class ReviewEntry {
  final String id;
  final String kind; // "daily", "weekly", "monthly"
  final DateTime completedAt;
  final String summary;
  final String accomplishments;
  final String lessons;

  const ReviewEntry({
    required this.id,
    required this.kind,
    required this.completedAt,
    required this.summary,
    required this.accomplishments,
    required this.lessons,
  });
}
