import express from 'express';
import cors from 'cors';
import cron from 'node-cron';
import db from './db.js';
import { executeSync } from './sync_engine.js';

const app = express();
const PORT = process.env.PORT || 8081;

app.use(cors());
app.use(express.json());

// In-memory buffer of recent live logs (keeps latest 100 log lines)
const liveLogs = [];
function addLog(msg) {
  const line = `[${new Date().toLocaleTimeString()}] ${msg}`;
  liveLogs.push(line);
  if (liveLogs.length > 100) liveLogs.shift();
  console.log(line);
}

// 1. Live SSE (Server-Sent Events) Stream for real-time console streaming in browser
app.get('/api/sync/live-logs', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  // Send current recent buffer
  for (const log of liveLogs) {
    res.write(`data: ${JSON.stringify({ log })}\n\n`);
  }

  const interval = setInterval(() => {
    res.write(': keep-alive\n\n');
  }, 15000);

  const logHandler = (msg) => {
    res.write(`data: ${JSON.stringify({ log: msg })}\n\n`);
  };

  req.on('close', () => {
    clearInterval(interval);
  });
});

// 2. Query logs as JSON array
app.get('/api/sync/logs', (req, res) => {
  res.json({ logs: liveLogs });
});

// 3. Health check & status endpoint
app.get('/api/health', (req, res) => {
  const count = db.prepare('SELECT COUNT(*) as total FROM official_lotto_results').get().total;
  const lastSync = db.prepare('SELECT * FROM sync_history ORDER BY id DESC LIMIT 1').get();
  res.json({
    status: 'ONLINE',
    service: 'LLIS Background Sync Worker & REST API',
    totalCachedDraws: count,
    lastSync,
  });
});

// 4. Query official lotto results
app.get('/api/pcso-results', (req, res) => {
  const { startDate, endDate, game, limit = 1000, offset = 0 } = req.query;

  let query = 'SELECT * FROM official_lotto_results WHERE 1=1';
  const params = [];

  if (startDate) {
    query += ' AND draw_date >= ?';
    params.push(startDate);
  }

  if (endDate) {
    query += ' AND draw_date <= ?';
    params.push(endDate);
  }

  if (game && game !== 'ALL') {
    query += ' AND (lotto_code = ? OR game_name LIKE ?)';
    params.push(game, `%${game}%`);
  }

  query += ' ORDER BY draw_date DESC, id DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit, 10), parseInt(offset, 10));

  const results = db.prepare(query).all(...params);

  const mapped = results.map(r => ({
    id: r.id,
    game: r.game_name,
    lotto_code: r.lotto_code,
    numbers: r.numbers,
    draw_date: r.draw_date,
    jackpot: r.jackpot,
    winners: r.winners,
    source: r.source,
  }));

  res.json(mapped);
});

// 5. Trigger on-demand sync from Admin UI
app.post('/api/sync/trigger', async (req, res) => {
  try {
    const { fromDate, toDate, gameFilter } = req.body || {};
    addLog(`Admin initiated on-demand sync via REST API (Game: ${gameFilter || 'ALL'})...`);
    const summary = await executeSync({
      runType: 'ON_DEMAND',
      fromDate,
      toDate,
      gameFilter,
      onLog: addLog,
    });
    res.json(summary);
  } catch (err) {
    addLog(`[ERROR] Sync failed: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// 6. Clear all results in central cache
app.post('/api/sync/clear', (req, res) => {
  try {
    const deleted = db.prepare('DELETE FROM official_lotto_results').run();
    addLog(`[Admin] Cleared all official results from central cache (${deleted.changes} deleted).`);
    res.json({ status: 'SUCCESS', deletedRecords: deleted.changes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 7. View sync history
app.get('/api/sync/history', (req, res) => {
  const history = db.prepare('SELECT * FROM sync_history ORDER BY id DESC LIMIT 20').all();
  res.json(history);
});

// 7. Automated Nightly Sync Cron Job (9:30 PM PHT)
cron.schedule('30 21 * * *', async () => {
  addLog('[Nightly Cron] 9:30 PM PHT reached: Running automated PCSO draw synchronization...');
  try {
    const today = new Date().toISOString().split('T')[0];
    await executeSync({
      runType: 'NIGHTLY_CRON',
      fromDate: today,
      toDate: today,
      onLog: addLog,
    });
    addLog('[Nightly Cron] Synchronization finished successfully.');
  } catch (err) {
    addLog(`[Nightly Cron ERROR] ${err.message}`);
  }
});

// Seed initial database cache on launch if empty
const count = db.prepare('SELECT COUNT(*) as total FROM official_lotto_results').get().total;
if (count === 0) {
  addLog('[LLIS Sync Server] Initializing 1-year historical cache in SQLite...');
  executeSync({ runType: 'INITIAL_BOOTSTRAP', onLog: addLog }).then(() => {
    addLog('[LLIS Sync Server] Initial cache bootstrap complete.');
  });
} else {
  addLog(`[LLIS Sync Server] Central cache ready with ${count} existing verified PCSO draw records.`);
}

app.listen(PORT, '0.0.0.0', () => {
  addLog(`================================================================`);
  addLog(`LLIS Official PCSO Background Sync Service running on PORT ${PORT}`);
  addLog(`REST API URL:   http://localhost:${PORT}/api/pcso-results`);
  addLog(`Live Logs URL:  http://localhost:${PORT}/api/sync/logs`);
  addLog(`Health Status:  http://localhost:${PORT}/api/health`);
  addLog(`Nightly Cron:   Daily at 21:30 (9:30 PM PHT)`);
  addLog(`================================================================`);
});

