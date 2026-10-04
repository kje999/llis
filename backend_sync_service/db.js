import Database from 'better-sqlite3';
import path from 'path';

const dbPath = path.resolve(process.cwd(), 'llis_central_sync.db');
const db = new Database(dbPath);

// Enable WAL mode for high performance
db.pragma('journal_mode = WAL');

// Initialize schema for official lotto results and sync logs
db.exec(`
  CREATE TABLE IF NOT EXISTS official_lotto_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lotto_code TEXT NOT NULL,
    game_name TEXT NOT NULL,
    numbers TEXT NOT NULL,
    draw_date TEXT NOT NULL,
    jackpot REAL NOT NULL DEFAULT 0.0,
    winners INTEGER NOT NULL DEFAULT 0,
    source TEXT DEFAULT 'PCSO_SCRAPER',
    scraped_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lotto_code, draw_date)
  );

  CREATE TABLE IF NOT EXISTS sync_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_type TEXT NOT NULL, -- 'NIGHTLY_CRON', 'ON_DEMAND', 'MANUAL_IMPORT'
    started_at DATETIME NOT NULL,
    completed_at DATETIME NOT NULL,
    status TEXT NOT NULL,
    records_found INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    error_message TEXT
  );

  CREATE INDEX IF NOT EXISTS idx_results_code_date ON official_lotto_results(lotto_code, draw_date);
  CREATE INDEX IF NOT EXISTS idx_results_draw_date ON official_lotto_results(draw_date DESC);
`);

console.log(`[LLIS Database] SQLite Central Cache initialized at ${dbPath}`);

export default db;

