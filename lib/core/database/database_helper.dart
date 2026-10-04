import 'database_executor.dart';
import 'database_factory.dart';
import 'sqlite_schema.dart';
import 'database_seeder.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static DatabaseExecutor? _db;

  DatabaseHelper._();

  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<DatabaseExecutor> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<DatabaseExecutor> _initDatabase() async {
    final db = await DatabaseFactory.createDatabase();

    // Create tables
    await db.execute(SqliteSchema.createUsersTable);
    await db.execute(SqliteSchema.createLottoTypesTable);
    await db.execute(SqliteSchema.createLottoResultsTable);
    await db.execute(SqliteSchema.createLuckyPicksTable);
    await db.execute(SqliteSchema.createSyncLogsTable);
    await db.execute(SqliteSchema.createPredictionHistoryTable);
    await db.execute(SqliteSchema.createAppSettingsTable);
    await db.execute(SqliteSchema.createNotificationsTable);
    await db.execute(SqliteSchema.createAuditLogsTable);

    // Create indexes
    for (final indexQuery in SqliteSchema.createIndexQueries) {
      await db.execute(indexQuery);
    }

    // Check if lotto_types is already seeded
    final types = await db.query('SELECT * FROM lotto_types');
    if (types.isEmpty) {
      await DatabaseSeeder.seed(db);
    }

    return db;
  }
}
