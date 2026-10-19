import { Router, Request, Response } from 'express';
import { pool } from '../config/db.js';

const router = Router();

// GET /api/tasks
router.get('/', async (req: Request, res: Response) => {
  try {
    const { workspaceId } = req.query;
    let query = 'SELECT * FROM tasks';
    const params: any[] = [];

    if (workspaceId) {
      query += ' WHERE workspace_id = $1';
      params.push(workspaceId);
    }
    query += ' ORDER BY created_at DESC;';

    const result = await pool.query(query, params);
    res.json({ success: true, tasks: result.rows });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/tasks
router.post('/', async (req: Request, res: Response) => {
  try {
    const { id, workspaceId, title, nextAction, importance, scheduledDate, durationMins } = req.body;
    const result = await pool.query(
      `INSERT INTO tasks (id, workspace_id, title, next_action, importance, scheduled_date, duration_mins)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *;`,
      [id, workspaceId, title, nextAction, importance || 'medium', scheduledDate, durationMins || 30]
    );
    res.status(201).json({ success: true, task: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// PATCH /api/tasks/:id/toggle
router.patch('/:id/toggle', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `UPDATE tasks
       SET is_completed = NOT is_completed,
           completed_at = CASE WHEN NOT is_completed THEN NOW() ELSE NULL END,
           updated_at = NOW()
       WHERE id = $1
       RETURNING *;`,
      [id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }
    res.json({ success: true, task: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
