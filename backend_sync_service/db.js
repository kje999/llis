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

  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'CLIENT',
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active INTEGER NOT NULL DEFAULT 1
  );

  CREATE TABLE IF NOT EXISTS lucky_picks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    lotto_type_id INTEGER NOT NULL,
    draw_date TEXT NOT NULL,
    number_1 INTEGER NOT NULL,
    number_2 INTEGER NOT NULL,
    number_3 INTEGER NOT NULL,
    number_4 INTEGER NOT NULL,
    number_5 INTEGER NOT NULL,
    number_6 INTEGER NOT NULL,
    generated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_checked INTEGER NOT NULL DEFAULT 0,
    match_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'PENDING'
  );

  CREATE INDEX IF NOT EXISTS idx_results_code_date ON official_lotto_results(lotto_code, draw_date);
  CREATE INDEX IF NOT EXISTS idx_results_draw_date ON official_lotto_results(draw_date DESC);
  CREATE INDEX IF NOT EXISTS idx_picks_user_date ON lucky_picks(user_id, draw_date);
`);

console.log(`[LLIS Database] SQLite Central Database initialized at ${dbPath}`);

export default db;

