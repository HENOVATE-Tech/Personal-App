# Personal Life OS — Backend REST API

High-performance Node.js & TypeScript Express REST API for **Personal Life OS**, connected to Supabase PostgreSQL and pre-configured for instant zero-configuration deployment to **Render** (`render.com`).

---

## 🚀 1-Click Deploy to Render

### Method A: Connect GitHub Repository (Recommended)
1. Go to [dashboard.render.com](https://dashboard.render.com/) and click **"New +" -> "Web Service"**.
2. Connect your GitHub repository: `https://github.com/HENOVATE-Tech/Personal-App`.
3. Configure the following fields:
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `node dist/index.js`
4. In **Environment Variables**, add:
   - `DATABASE_URL`: `postgresql://postgres:henzsolo31012002!@db.actqetxmyfdmoqyykwxj.supabase.co:5432/postgres`
   - `NODE_ENV`: `production`
5. Click **"Create Web Service"**.
6. Once deployed, Render will provide a public URL like:
   `https://personal-life-os-api.onrender.com`
7. In the Flutter App, navigate to **Settings** -> **Render REST API Backend**, paste your URL, and click **"Save & Test"**!

---

### Method B: Render Blueprint (render.yaml)
1. In Render Dashboard, click **"New +" -> "Blueprint"**.
2. Point it to this repository. Render automatically reads `backend/render.yaml` and deploys the web service with health checks configured at `/health`.

---

## 📡 API Endpoints

### 1. Health & Status
- **`GET /health`**: Live database connection and service health ping.
- **`GET /api/sync/status`**: Remote PostgreSQL schema table counter and latency check.

### 2. Synchronization
- **`POST /api/sync/push`**: Batch upserts local models (tasks, accounts, categories, budgets, ledger transactions, SMS debit alerts) into Supabase PostgreSQL.
- **`GET /api/sync/pull?since=ISO8601`**: Fetches newly created or updated entities from PostgreSQL.

### 3. Finance & Governance
- **`GET /api/finance/accounts`**: Returns all financial accounts and live balances.
- **`GET /api/finance/categories`**: Returns spending categories and discretionary flags.
- **`GET /api/finance/budgets`**: Returns monthly budget limits and current expenditure.
- **`POST /api/finance/transactions`**: Posts a strict double-entry ledger journal ($\sum \text{movements} = 0$).

---

## 💻 Local Development
```bash
cd backend
npm install
npm run dev
```
Test health locally:
```bash
curl http://localhost:5000/health
```
