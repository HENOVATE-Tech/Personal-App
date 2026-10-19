import { Router, Request, Response } from 'express';
import { pool } from '../config/db.js';

const router = Router();

// GET /api/sync/status - Health and table statistics
router.get('/status', async (_req: Request, res: Response) => {
  try {
    const start = Date.now();
    const countRes = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
    );
    const latencyMs = Date.now() - start;

    res.json({
      status: 'online',
      provider: 'Supabase PostgreSQL',
      latencyMs,
      tableCount: countRes.rowCount,
      tables: countRes.rows.map((r) => r.table_name),
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/sync/push - Idempotent upsert from mobile app to Supabase
router.post('/push', async (req: Request, res: Response) => {
  const client = await pool.connect();
  try {
    const {
      workspaces = [],
      accounts = [],
      categories = [],
      budgets = [],
      tasks = [],
      routines = [],
      careChecklist = [],
      chores = [],
      transactions = [],
      movements = [],
      smsAlerts = [],
    } = req.body;

    let pushedCount = 0;
    await client.query('BEGIN');

    // 1. Workspaces
    for (const ws of workspaces) {
      await client.query(
        `INSERT INTO workspaces (id, name, type, color_value)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, color_value = EXCLUDED.color_value;`,
        [ws.id, ws.name, ws.type, ws.colorValue]
      );
      pushedCount++;
    }

    // 2. Financial Accounts
    for (const acc of accounts) {
      await client.query(
        `INSERT INTO financial_accounts (id, name, account_type, currency, opening_balance_kobo, balance_kobo, is_archived, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
         ON CONFLICT (id) DO UPDATE SET balance_kobo = EXCLUDED.balance_kobo, is_archived = EXCLUDED.is_archived, updated_at = NOW();`,
        [acc.id, acc.name, acc.accountType, acc.currency || 'NGN', acc.openingBalanceKobo, acc.balanceKobo, acc.isArchived || false]
      );
      pushedCount++;
    }

    // 3. Financial Categories
    for (const cat of categories) {
      await client.query(
        `INSERT INTO financial_categories (id, name, type, icon_name, color_value, is_essential)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_essential = EXCLUDED.is_essential;`,
        [cat.id, cat.name, cat.type, cat.iconName, cat.colorValue, cat.isEssential ?? true]
      );
      pushedCount++;
    }

    // 4. Budgets
    for (const b of budgets) {
      await client.query(
        `INSERT INTO budgets (id, category_id, period_month_year, allocated_kobo, spent_kobo, rollover_eligible, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         ON CONFLICT (id) DO UPDATE SET allocated_kobo = EXCLUDED.allocated_kobo, spent_kobo = EXCLUDED.spent_kobo, updated_at = NOW();`,
        [b.id, b.categoryId, b.periodMonthYear, b.allocatedKobo, b.spentKobo || 0, b.rolloverEligible || false]
      );
      pushedCount++;
    }

    // 5. Tasks
    for (const t of tasks) {
      await client.query(
        `INSERT INTO tasks (id, workspace_id, title, next_action, importance, is_top_priority, is_completed, completed_at, scheduled_date, duration_mins, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
         ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, is_completed = EXCLUDED.is_completed, completed_at = EXCLUDED.completed_at, updated_at = NOW();`,
        [t.id, t.workspaceId, t.title, t.nextAction || '', t.importance, t.isTopPriority || false, t.isCompleted || false, t.completedAt, t.scheduledDate, t.durationMins || 30]
      );
      pushedCount++;
    }

    // 6. Routine Templates
    for (const rt of routines) {
      await client.query(
        `INSERT INTO routine_templates (id, title, category, preferred_time_local, target_duration_mins)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING;`,
        [rt.id, rt.title, rt.category, rt.preferredTimeLocal, rt.targetDurationMins]
      );
      pushedCount++;
    }

    // 7. Care Checklist
    for (const care of careChecklist) {
      await client.query(
        `INSERT INTO care_checklist_items (id, title, period, is_completed)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (id) DO UPDATE SET is_completed = EXCLUDED.is_completed;`,
        [care.id, care.title, care.period, care.isCompleted || false]
      );
      pushedCount++;
    }

    // 8. Chores
    for (const ch of chores) {
      await client.query(
        `INSERT INTO chores (id, workspace_id, title, frequency, estimated_mins, last_completed_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET last_completed_at = EXCLUDED.last_completed_at;`,
        [ch.id, ch.workspaceId, ch.title, ch.frequency, ch.estimatedMins || 30, ch.lastCompletedAt]
      );
      pushedCount++;
    }

    // 9. Ledger Transactions & Movements
    for (const tx of transactions) {
      await client.query(
        `INSERT INTO ledger_transactions (id, type, effective_at, memo, workspace_id, original_transaction_id, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO NOTHING;`,
        [tx.id, tx.type, tx.effectiveAt, tx.memo, tx.workspaceId, tx.originalTransactionId, tx.createdAt || new Date()]
      );
      pushedCount++;
    }

    for (const m of movements) {
      await client.query(
        `INSERT INTO ledger_movements (id, transaction_id, account_id, category_id, amount_kobo, currency)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO NOTHING;`,
        [m.id, m.transactionId, m.accountId, m.categoryId, m.amountKobo, m.currency || 'NGN']
      );
      pushedCount++;
    }

    // 10. SMS Debit Alerts
    for (const alert of smsAlerts) {
      await client.query(
        `INSERT INTO sms_debit_alerts (id, sender, raw_body, amount_kobo, account_last4, memo, is_debit, received_at, suggested_category_id, is_processed, is_ignored)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
         ON CONFLICT (id) DO UPDATE SET is_processed = EXCLUDED.is_processed, is_ignored = EXCLUDED.is_ignored;`,
        [alert.id, alert.sender, alert.rawBody, alert.amountKobo, alert.accountLast4, alert.memo, alert.isDebit ?? true, alert.receivedAt, alert.suggestedCategoryId, alert.isProcessed || false, alert.isIgnored || false]
      );
      pushedCount++;
    }

    await client.query('COMMIT');
    res.json({ success: true, recordsPushed: pushedCount, timestamp: new Date() });
  } catch (err: any) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: err.message });
  } finally {
    client.release();
  }
});

// GET /api/sync/pull - Hydrate local app from Supabase cloud
router.get('/pull', async (_req: Request, res: Response) => {
  try {
    const workspaces = (await pool.query('SELECT * FROM workspaces;')).rows;
    const accounts = (await pool.query('SELECT * FROM financial_accounts;')).rows;
    const categories = (await pool.query('SELECT * FROM financial_categories;')).rows;
    const budgets = (await pool.query('SELECT * FROM budgets;')).rows;
    const tasks = (await pool.query('SELECT * FROM tasks;')).rows;
    const routines = (await pool.query('SELECT * FROM routine_templates;')).rows;
    const careChecklist = (await pool.query('SELECT * FROM care_checklist_items;')).rows;
    const chores = (await pool.query('SELECT * FROM chores;')).rows;
    const transactions = (await pool.query('SELECT * FROM ledger_transactions ORDER BY effective_at DESC LIMIT 50;')).rows;
    const movements = (await pool.query('SELECT * FROM ledger_movements;')).rows;
    const smsAlerts = (await pool.query('SELECT * FROM sms_debit_alerts WHERE is_processed = false AND is_ignored = false;')).rows;

    res.json({
      success: true,
      data: {
        workspaces,
        accounts,
        categories,
        budgets,
        tasks,
        routines,
        careChecklist,
        chores,
        transactions,
        movements,
        smsAlerts,
      },
      timestamp: new Date(),
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
