import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import syncRouter from './routes/sync.js';
import tasksRouter from './routes/tasks.js';
import financeRouter from './routes/finance.js';
import { pool } from './config/db.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Health Check Endpoint (Render uses this to verify deployment health)
app.get('/health', async (_req: Request, res: Response) => {
  try {
    const result = await pool.query('SELECT NOW();');
    res.json({
      status: 'healthy',
      service: 'Personal Life OS Backend API',
      database: 'connected',
      timestamp: result.rows[0].now,
      environment: process.env.NODE_ENV || 'development',
    });
  } catch (err: any) {
    res.status(503).json({
      status: 'degraded',
      error: err.message,
    });
  }
});

app.get('/', (_req: Request, res: Response) => {
  res.json({
    message: 'Welcome to Personal Life OS REST API Server',
    version: '1.0.0',
    documentation: {
      health: 'GET /health',
      syncStatus: 'GET /api/sync/status',
      syncPush: 'POST /api/sync/push',
      syncPull: 'GET /api/sync/pull',
      tasks: 'GET /api/tasks',
      financeAccounts: 'GET /api/finance/accounts',
      financeBudgets: 'GET /api/finance/budgets',
      financeTransactions: 'POST /api/finance/transactions',
    },
  });
});

// Mount Routes
app.use('/api/sync', syncRouter);
app.use('/api/tasks', tasksRouter);
app.use('/api/finance', financeRouter);

// Start Server
app.listen(port, () => {
  console.log(`🚀 Personal Life OS API running on port ${port}`);
  console.log(`📊 Health check available at http://localhost:${port}/health`);
});
