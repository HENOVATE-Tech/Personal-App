import 'package:postgres/postgres.dart';
import '../database/local_database.dart';
import '../database/schema_models.dart';

class SyncResult {
  final bool isSuccess;
  final int recordsPushed;
  final int recordsPulled;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.isSuccess,
    this.recordsPushed = 0,
    this.recordsPulled = 0,
    this.errorMessage,
    required this.timestamp,
  });
}

class SupabaseSyncService {
  static final SupabaseSyncService instance = SupabaseSyncService._internal();
  SupabaseSyncService._internal();

  static const String host = 'db.actqetxmyfdmoqyykwxj.supabase.co';
  static const int port = 5432;
  static const String database = 'postgres';
  static const String username = 'postgres';
  static const String password = 'henzsolo31012002!';

  Future<Connection> _openConnection() async {
    return await Connection.open(
      Endpoint(
        host: host,
        database: database,
        username: username,
        password: password,
        port: port,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: Duration(seconds: 10),
      ),
    );
  }

  /// Test database reachability
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final conn = await _openConnection();
      final verRes = await conn.execute('SELECT version();');
      final version = verRes.first.first.toString();

      final countRes = await conn.execute(
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';",
      );
      final tableCount = countRes.first.first as int;

      await conn.close();
      return {
        'connected': true,
        'version': version,
        'tableCount': tableCount,
        'host': host,
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'host': host,
      };
    }
  }

  /// Push all local records to Supabase PostgreSQL (Idempotent Upsert)
  Future<SyncResult> pushToSupabase() async {
    final now = DateTime.now();
    Connection? conn;
    try {
      conn = await _openConnection();
      final db = LocalDatabase.instance;
      int pushedCount = 0;

      // 1. Workspaces
      for (final ws in db.getWorkspaces()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO workspaces (id, name, type, color_value) '
            'VALUES (@id, @name, @type, @color) '
            'ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, color_value = EXCLUDED.color_value;',
          ),
          parameters: {
            'id': ws.id,
            'name': ws.name,
            'type': ws.type,
            'color': ws.colorValue,
          },
        );
        pushedCount++;
      }

      // 2. Financial Accounts
      for (final acc in db.getFinancialAccounts()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO financial_accounts (id, name, account_type, currency, opening_balance_kobo, balance_kobo, is_archived, updated_at) '
            'VALUES (@id, @name, @type, @curr, @openBal, @bal, @archived, NOW()) '
            'ON CONFLICT (id) DO UPDATE SET balance_kobo = EXCLUDED.balance_kobo, is_archived = EXCLUDED.is_archived, updated_at = NOW();',
          ),
          parameters: {
            'id': acc.id,
            'name': acc.name,
            'type': acc.accountType.name,
            'curr': acc.currency,
            'openBal': acc.openingBalanceKobo,
            'bal': acc.balanceKobo,
            'archived': acc.isArchived,
          },
        );
        pushedCount++;
      }

      // 3. Financial Categories
      for (final cat in db.getFinancialCategories()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO financial_categories (id, name, type, icon_name, color_value, is_essential) '
            'VALUES (@id, @name, @type, @icon, @color, @essential) '
            'ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_essential = EXCLUDED.is_essential;',
          ),
          parameters: {
            'id': cat.id,
            'name': cat.name,
            'type': cat.type,
            'icon': cat.iconName,
            'color': cat.colorValue,
            'essential': cat.isEssential,
          },
        );
        pushedCount++;
      }

      // 4. Budgets
      for (final b in db.getBudgets()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO budgets (id, category_id, period_month_year, allocated_kobo, spent_kobo, rollover_eligible, updated_at) '
            'VALUES (@id, @catId, @period, @alloc, @spent, @rollover, NOW()) '
            'ON CONFLICT (id) DO UPDATE SET allocated_kobo = EXCLUDED.allocated_kobo, spent_kobo = EXCLUDED.spent_kobo, updated_at = NOW();',
          ),
          parameters: {
            'id': b.id,
            'catId': b.categoryId,
            'period': b.periodMonthYear,
            'alloc': b.allocatedKobo,
            'spent': b.spentKobo,
            'rollover': b.rolloverEligible,
          },
        );
        pushedCount++;
      }

      // 5. Tasks
      for (final t in db.getTasks()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO tasks (id, workspace_id, title, next_action, importance, is_top_priority, is_completed, completed_at, scheduled_date, duration_mins, recurrence_rule, updated_at) '
            'VALUES (@id, @wsId, @title, @nextAction, @importance, @isTop, @isCompleted, @compAt, @schedDate, @duration, @recurrence, NOW()) '
            'ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, is_completed = EXCLUDED.is_completed, completed_at = EXCLUDED.completed_at, updated_at = NOW();',
          ),
          parameters: {
            'id': t.id,
            'wsId': t.workspaceId,
            'title': t.title,
            'nextAction': t.nextAction,
            'importance': t.importance.name,
            'isTop': t.isTopPriority,
            'isCompleted': t.status == TaskStatus.completed,
            'compAt': t.completedAt,
            'schedDate': t.scheduledDate,
            'duration': t.estimateMinutes,
            'recurrence': null,
          },
        );
        pushedCount++;
      }

      // 6. Routine Templates
      for (final rt in db.getRoutineTemplates()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO routine_templates (id, title, category, preferred_time_local, target_duration_mins) '
            'VALUES (@id, @title, @category, @time, @duration) '
            'ON CONFLICT (id) DO NOTHING;',
          ),
          parameters: {
            'id': rt.id,
            'title': rt.title,
            'category': rt.category,
            'time': rt.preferredTimeLocal,
            'duration': rt.targetDurationMins,
          },
        );
        pushedCount++;
      }

      // 7. Care Checklist Items
      for (final care in db.getCareChecklist()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO care_checklist_items (id, title, period, is_completed, last_completed_at) '
            'VALUES (@id, @title, @period, @completed, @lastComp) '
            'ON CONFLICT (id) DO UPDATE SET is_completed = EXCLUDED.is_completed, last_completed_at = EXCLUDED.last_completed_at;',
          ),
          parameters: {
            'id': care.id,
            'title': care.title,
            'period': care.period,
            'completed': care.isCompleted,
            'lastComp': null,
          },
        );
        pushedCount++;
      }

      // 8. Chores
      for (final ch in db.getChores()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO chores (id, workspace_id, title, frequency, estimated_mins, last_completed_at) '
            'VALUES (@id, @wsId, @title, @freq, @mins, @lastComp) '
            'ON CONFLICT (id) DO UPDATE SET last_completed_at = EXCLUDED.last_completed_at;',
          ),
          parameters: {
            'id': ch.id,
            'wsId': ch.workspaceId,
            'title': ch.title,
            'freq': ch.frequency,
            'mins': ch.estimatedMins,
            'lastComp': ch.lastCompletedAt,
          },
        );
        pushedCount++;
      }

      // 9. Ledger Transactions & Movements
      for (final tx in db.getLedgerTransactions()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO ledger_transactions (id, type, effective_at, memo, workspace_id, original_transaction_id, created_at) '
            'VALUES (@id, @type, @effectiveAt, @memo, @wsId, @origId, @createdAt) '
            'ON CONFLICT (id) DO NOTHING;',
          ),
          parameters: {
            'id': tx.id,
            'type': tx.type.name,
            'effectiveAt': tx.effectiveAt,
            'memo': tx.memo,
            'wsId': tx.workspaceId,
            'origId': tx.originalTransactionId,
            'createdAt': tx.createdAt,
          },
        );
        pushedCount++;
      }

      for (final m in db.getLedgerMovements()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO ledger_movements (id, transaction_id, account_id, category_id, amount_kobo, currency) '
            'VALUES (@id, @txId, @accId, @catId, @amt, @curr) '
            'ON CONFLICT (id) DO NOTHING;',
          ),
          parameters: {
            'id': m.id,
            'txId': m.transactionId,
            'accId': m.accountId,
            'catId': m.categoryId,
            'amt': m.amountKobo,
            'curr': m.currency,
          },
        );
        pushedCount++;
      }

      // 10. SMS Debit Alerts
      for (final alert in db.getSmsDebitAlerts()) {
        await conn.execute(
          Sql.named(
            'INSERT INTO sms_debit_alerts (id, sender, raw_body, amount_kobo, account_last4, memo, is_debit, received_at, suggested_category_id, is_processed, is_ignored) '
            'VALUES (@id, @sender, @body, @amt, @accLast4, @memo, @isDebit, @recAt, @catId, @isProc, @isIgn) '
            'ON CONFLICT (id) DO UPDATE SET is_processed = EXCLUDED.is_processed, is_ignored = EXCLUDED.is_ignored;',
          ),
          parameters: {
            'id': alert.id,
            'sender': alert.sender,
            'body': alert.rawBody,
            'amt': alert.amountKobo,
            'accLast4': alert.accountLast4,
            'memo': alert.memo,
            'isDebit': alert.isDebit,
            'recAt': alert.receivedAt,
            'catId': alert.suggestedCategoryId,
            'isProc': alert.isProcessed,
            'isIgn': alert.isIgnored,
          },
        );
        pushedCount++;
      }

      await conn.close();

      return SyncResult(
        isSuccess: true,
        recordsPushed: pushedCount,
        timestamp: now,
      );
    } catch (e) {
      if (conn != null) {
        try {
          await conn.close();
        } catch (_) {}
      }
      return SyncResult(
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: now,
      );
    }
  }

  /// Pull remote records from Supabase into LocalDatabase
  Future<SyncResult> pullFromSupabase() async {
    final now = DateTime.now();
    Connection? conn;
    try {
      conn = await _openConnection();
      final db = LocalDatabase.instance;
      int pulledCount = 0;

      // 1. Pull Categories
      final catRows = await conn.execute(
        'SELECT id, name, type, icon_name, color_value, is_essential FROM financial_categories;',
      );
      for (final r in catRows) {
        final cat = FinancialCategory(
          id: r[0] as String,
          name: r[1] as String,
          type: r[2] as String,
          iconName: r[3] as String,
          colorValue: (r[4] as num).toInt(),
          isEssential: r[5] as bool? ?? true,
        );
        db.updateCategory(cat);
        pulledCount++;
      }

      // 2. Pull Budgets
      final budgetRows = await conn.execute(
        'SELECT id, category_id, period_month_year, allocated_kobo, spent_kobo, rollover_eligible FROM budgets;',
      );
      for (final r in budgetRows) {
        final b = Budget(
          id: r[0] as String,
          categoryId: r[1] as String,
          periodMonthYear: r[2] as String,
          allocatedKobo: (r[3] as num).toInt(),
          spentKobo: (r[4] as num).toInt(),
          rolloverEligible: r[5] as bool? ?? false,
        );
        db.upsertBudget(b);
        pulledCount++;
      }

      await conn.close();
      return SyncResult(
        isSuccess: true,
        recordsPulled: pulledCount,
        timestamp: now,
      );
    } catch (e) {
      if (conn != null) {
        try {
          await conn.close();
        } catch (_) {}
      }
      return SyncResult(
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: now,
      );
    }
  }
}
