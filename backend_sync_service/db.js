import Database from 'better-sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dbPath = path.resolve(__dirname, 'llis_central_sync.db');
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

  CREATE TABLE IF NOT EXISTS system_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE INDEX IF NOT EXISTS idx_results_code_date ON official_lotto_results(lotto_code, draw_date);
  CREATE INDEX IF NOT EXISTS idx_results_draw_date ON official_lotto_results(draw_date DESC);
  CREATE INDEX IF NOT EXISTS idx_picks_user_date ON lucky_picks(user_id, draw_date);
`);

export function getConfig(key, defaultValue = null) {
  try {
    const row = db.prepare('SELECT value FROM system_config WHERE key = ?').get(key);
    return row ? row.value : defaultValue;
  } catch (err) {
    return defaultValue;
  }
}

export function setConfig(key, value) {
  try {
    const stmt = db.prepare(`
      INSERT INTO system_config (key, value, updated_at)
      VALUES (?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        updated_at = CURRENT_TIMESTAMP
    `);
    stmt.run(key, String(value));
    return true;
  } catch (err) {
    console.error('Failed to set system_config:', err);
    return false;
  }
}

// Default config: auto_scrape_enabled = 'true'
if (getConfig('auto_scrape_enabled') === null) {
  setConfig('auto_scrape_enabled', 'true');
}

import('crypto').then((crypto) => {
  function hashPassword(password) {
    return crypto.createHash('sha256').update(`llis_pcso_secret_salt_2026:${password}`).digest('hex');
  }

  // Remove any legacy seeded test account
  db.prepare("DELETE FROM users WHERE LOWER(username) = 'kenth'").run();

  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
  if (userCount === 0) {
    const insertUser = db.prepare(`
      INSERT INTO users (username, password_hash, role, full_name, email, is_active)
      VALUES (?, ?, ?, ?, ?, 1)
    `);

    // Real Persistent Accounts in SQLite
    insertUser.run('admin', hashPassword('Admin@2026'), 'ADMIN', 'System Administrator', 'admin@pcso-llis.gov.ph');
    insertUser.run('player1', hashPassword('Player@2026'), 'CLIENT', 'Lucky Lotto Player', 'player@pcso-llis.gov.ph');
    console.log('[LLIS Database] Real users initialized in SQLite: "admin" & "player1".');
  }
});

console.log(`[LLIS Database] SQLite Central Database initialized at ${dbPath}`);

export default db;


