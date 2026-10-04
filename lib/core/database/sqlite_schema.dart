class SqliteSchema {
  SqliteSchema._();

  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      full_name TEXT NOT NULL,
      email TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    );
  ''';

  static const String createLottoTypesTable = '''
    CREATE TABLE IF NOT EXISTS lotto_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      min_number INTEGER NOT NULL,
      max_number INTEGER NOT NULL,
      number_count INTEGER NOT NULL DEFAULT 6,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createLottoResultsTable = '''
    CREATE TABLE IF NOT EXISTS lotto_results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lotto_type_id INTEGER NOT NULL,
      draw_date TEXT NOT NULL,
      number_1 INTEGER NOT NULL,
      number_2 INTEGER NOT NULL,
      number_3 INTEGER NOT NULL,
      number_4 INTEGER NOT NULL,
      number_5 INTEGER NOT NULL,
      number_6 INTEGER NOT NULL,
      jackpot_prize REAL NOT NULL,
      winners INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'PCSO',
      source_url TEXT NOT NULL DEFAULT 'https://www.pcso.gov.ph/searchlottoresult.aspx',
      scraped_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (lotto_type_id) REFERENCES lotto_types(id)
    );
  ''';

  static const String createLuckyPicksTable = '''
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
      generated_at TEXT NOT NULL,
      is_checked INTEGER NOT NULL DEFAULT 0,
      match_count INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'PENDING',
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (lotto_type_id) REFERENCES lotto_types(id)
    );
  ''';

  static const String createSyncLogsTable = '''
    CREATE TABLE IF NOT EXISTS synchronization_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      started_at TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      status TEXT NOT NULL,
      records_found INTEGER NOT NULL DEFAULT 0,
      records_inserted INTEGER NOT NULL DEFAULT 0,
      records_updated INTEGER NOT NULL DEFAULT 0,
      records_skipped INTEGER NOT NULL DEFAULT 0,
      error_message TEXT,
      source_url TEXT NOT NULL
    );
  ''';

  static const String createPredictionHistoryTable = '''
    CREATE TABLE IF NOT EXISTS prediction_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lotto_type_id INTEGER NOT NULL,
      prediction_date TEXT NOT NULL,
      analysis_start_date TEXT NOT NULL,
      analysis_end_date TEXT NOT NULL,
      algorithm TEXT NOT NULL,
      predicted_numbers TEXT NOT NULL,
      confidence_score REAL NOT NULL,
      analysis_summary TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (lotto_type_id) REFERENCES lotto_types(id)
    );
  ''';

  static const String createAppSettingsTable = '''
    CREATE TABLE IF NOT EXISTS app_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      setting_key TEXT NOT NULL UNIQUE,
      setting_value TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''';

  static const String createNotificationsTable = '''
    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      category TEXT NOT NULL,
      is_read INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );
  ''';

  static const String createAuditLogsTable = '''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      action TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id INTEGER,
      description TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  ''';

  static const List<String> createIndexQueries = [
    'CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);',
    'CREATE INDEX IF NOT EXISTS idx_results_draw_date ON lotto_results (draw_date);',
    'CREATE INDEX IF NOT EXISTS idx_results_type_id ON lotto_results (lotto_type_id);',
    'CREATE INDEX IF NOT EXISTS idx_lucky_picks_user ON lucky_picks (user_id);',
    'CREATE INDEX IF NOT EXISTS idx_lucky_picks_draw_date ON lucky_picks (draw_date);',
    'CREATE INDEX IF NOT EXISTS idx_lucky_picks_type ON lucky_picks (lotto_type_id);',
    'CREATE INDEX IF NOT EXISTS idx_prediction_type ON prediction_history (lotto_type_id);',
    'CREATE INDEX IF NOT EXISTS idx_prediction_date ON prediction_history (prediction_date);',
  ];
}
