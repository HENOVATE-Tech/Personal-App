import { Router, Request, Response } from 'express';
import { pool } from '../config/db.js';

const router = Router();

// GET /api/finance/accounts
router.get('/accounts', async (_req: Request, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM financial_accounts ORDER BY name ASC;');
    res.json({ success: true, accounts: result.rows });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/finance/categories
router.get('/categories', async (_req: Request, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM financial_categories ORDER BY name ASC;');
    res.json({ success: true, categories: result.rows });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/finance/categories
router.post('/categories', async (req: Request, res: Response) => {
  try {
    const { id, name, type, iconName, colorValue, isEssential } = req.body;
    const result = await pool.query(
      `INSERT INTO financial_categories (id, name, type, icon_name, color_value, is_essential)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *;`,
      [id, name, type, iconName, colorValue, isEssential ?? true]
    );
    res.status(201).json({ success: true, category: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/finance/budgets
router.get('/budgets', async (req: Request, res: Response) => {
  try {
    const { period } = req.query;
    let query = `
      SELECT b.*, c.name as category_name, c.is_essential, c.color_value
      FROM budgets b
      JOIN financial_categories c ON b.category_id = c.id
    `;
    const params: any[] = [];
    if (period) {
      query += ' WHERE b.period_month_year = $1';
      params.push(period);
    }
    const result = await pool.query(query, params);
    res.json({ success: true, budgets: result.rows });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/finance/budgets (Upsert)
router.post('/budgets', async (req: Request, res: Response) => {
  try {
    const { id, categoryId, periodMonthYear, allocatedKobo } = req.body;
    const result = await pool.query(
      `INSERT INTO budgets (id, category_id, period_month_year, allocated_kobo, updated_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (id) DO UPDATE SET allocated_kobo = EXCLUDED.allocated_kobo, updated_at = NOW()
       RETURNING *;`,
      [id, categoryId, periodMonthYear, allocatedKobo]
    );
    res.status(201).json({ success: true, budget: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/finance/transactions - Atomic Balanced Double Entry Transaction
router.post('/transactions', async (req: Request, res: Response) => {
  const client = await pool.connect();
  try {
    const { id, type, effectiveAt, memo, workspaceId, movements } = req.body;

    // Validate double-entry sum invariant: sum(amountKobo) == 0
    const sum = movements.reduce((acc: number, m: any) => acc + Number(m.amountKobo), 0);
    if (sum !== 0) {
      return res.status(400).json({
        success: false,
        error: `Unbalanced journal: Sum of movements is ${sum} (must equal 0)`,
      });
    }

    await client.query('BEGIN');

    // 1. Insert transaction
    await client.query(
      `INSERT INTO ledger_transactions (id, type, effective_at, memo, workspace_id, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW());`,
      [id, type, effectiveAt || new Date(), memo, workspaceId]
    );

    // 2. Insert movements and update account balances
    for (const m of movements) {
      await client.query(
        `INSERT INTO ledger_movements (id, transaction_id, account_id, category_id, amount_kobo, currency)
         VALUES ($1, $2, $3, $4, $5, $6);`,
        [m.id, id, m.accountId || null, m.categoryId || null, m.amountKobo, m.currency || 'NGN']
      );

      if (m.accountId) {
        await client.query(
          `UPDATE financial_accounts
           SET balance_kobo = balance_kobo + $1, updated_at = NOW()
           WHERE id = $2;`,
          [m.amountKobo, m.accountId]
        );
      }
    }

    await client.query('COMMIT');
    res.status(201).json({ success: true, transactionId: id });
  } catch (err: any) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: err.message });
  } finally {
    client.release();
  }
});

// GET /api/finance/income-sources
router.get('/income-sources', async (_req: Request, res: Response) => {
  try {
    const result = await pool.query('SELECT * FROM income_sources WHERE is_active = true ORDER BY name ASC;');
    res.json({ success: true, incomeSources: result.rows });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/finance/income-sources (Upsert)
router.post('/income-sources', async (req: Request, res: Response) => {
  try {
    const { id, name, accountId, expectedMonthlyKobo, receivedKobo, workspaceId, isActive } = req.body;
    const result = await pool.query(
      `INSERT INTO income_sources (id, name, account_id, expected_monthly_kobo, received_kobo, workspace_id, is_active, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         account_id = EXCLUDED.account_id,
         expected_monthly_kobo = EXCLUDED.expected_monthly_kobo,
         received_kobo = EXCLUDED.received_kobo,
         workspace_id = EXCLUDED.workspace_id,
         is_active = EXCLUDED.is_active,
         updated_at = NOW()
       RETURNING *;`,
      [id, name, accountId, expectedMonthlyKobo || 0, receivedKobo || 0, workspaceId, isActive ?? true]
    );
    res.status(201).json({ success: true, incomeSource: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// DELETE /api/finance/income-sources/:id
router.delete('/income-sources/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM income_sources WHERE id = $1;', [id]);
    res.json({ success: true, message: 'Income source deleted' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// DELETE /api/finance/budgets/:id
router.delete('/budgets/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM budgets WHERE id = $1;', [id]);
    res.json({ success: true, message: 'Budget deleted' });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
