import { Router, Request, Response } from 'express';
import { pool } from '../config/db.js';

const router = Router();

// GET /api/notes - Query notes with category & search filters
router.get('/', async (req: Request, res: Response) => {
  try {
    const { category, search, workspaceId } = req.query;
    let query = 'SELECT * FROM notes WHERE 1=1';
    const params: any[] = [];

    if (category) {
      params.push(category);
      query += ` AND category = $${params.length}`;
    }

    if (workspaceId) {
      params.push(workspaceId);
      query += ` AND workspace_id = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      query += ` AND (title ILIKE $${params.length} OR content ILIKE $${params.length} OR scripture_reference ILIKE $${params.length})`;
    }

    query += ' ORDER BY is_pinned DESC, updated_at DESC;';

    const result = await pool.query(query, params);
    res.json({
      success: true,
      count: result.rowCount,
      notes: result.rows,
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/notes - Create or update note
router.post('/', async (req: Request, res: Response) => {
  try {
    const {
      id,
      workspaceId = 'ws-personal',
      title,
      content,
      category,
      subCategory = null,
      tags = [],
      scriptureReference = null,
      isPinned = false,
      colorValue = 4294967295,
      linkedTaskId = null,
    } = req.body;

    if (!id || !title || !category) {
      return res.status(400).json({ success: false, error: 'id, title, and category are required' });
    }

    const result = await pool.query(
      `INSERT INTO notes (id, workspace_id, title, content, category, sub_category, tags, scripture_reference, is_pinned, color_value, linked_task_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
       ON CONFLICT (id) DO UPDATE SET
         workspace_id = EXCLUDED.workspace_id,
         title = EXCLUDED.title,
         content = EXCLUDED.content,
         category = EXCLUDED.category,
         sub_category = EXCLUDED.sub_category,
         tags = EXCLUDED.tags,
         scripture_reference = EXCLUDED.scripture_reference,
         is_pinned = EXCLUDED.is_pinned,
         color_value = EXCLUDED.color_value,
         linked_task_id = EXCLUDED.linked_task_id,
         updated_at = NOW()
       RETURNING *;`,
      [id, workspaceId, title, content || '', category, subCategory, tags, scriptureReference, isPinned, colorValue, linkedTaskId]
    );

    res.json({
      success: true,
      note: result.rows[0],
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// DELETE /api/notes/:id - Delete note
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM notes WHERE id = $1;', [id]);
    res.json({ success: true, message: `Note ${id} deleted` });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/notes/:id/pin - Toggle pin status
router.post('/:id/pin', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'UPDATE notes SET is_pinned = NOT is_pinned, updated_at = NOW() WHERE id = $1 RETURNING *;',
      [id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Note not found' });
    }
    res.json({ success: true, isPinned: result.rows[0].is_pinned, note: result.rows[0] });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/notes/:id/convert-to-task - Convert note into an actionable task
router.post('/:id/convert-to-task', async (req: Request, res: Response) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { workspaceId, importance = 'high', estimateMinutes = 30, scheduledDate = null } = req.body;

    await client.query('BEGIN');
    const noteRes = await client.query('SELECT * FROM notes WHERE id = $1;', [id]);
    if (noteRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Note not found' });
    }
    const note = noteRes.rows[0];

    const taskId = `task-from-note-${Date.now()}`;
    const targetWs = workspaceId || note.workspace_id || 'ws-personal';

    // Insert task into tasks table
    await client.query(
      `INSERT INTO tasks (id, workspace_id, title, next_action, importance, is_top_priority, is_completed, scheduled_date, duration_mins, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, true, false, $6, $7, NOW(), NOW());`,
      [taskId, targetWs, note.title, note.content ? note.content.slice(0, 200) : 'Execute note action', importance, scheduledDate, estimateMinutes]
    );

    // Link task back to note
    await client.query('UPDATE notes SET linked_task_id = $1, updated_at = NOW() WHERE id = $2;', [taskId, id]);

    await client.query('COMMIT');
    res.json({
      success: true,
      message: 'Note converted to actionable task',
      taskId,
      workspaceId: targetWs,
    });
  } catch (err: any) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: err.message });
  } finally {
    client.release();
  }
});

export default router;
