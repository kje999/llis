import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'database_executor.dart';
import 'sqlite3_executor.dart';
import 'in_memory_database_executor.dart';

class DatabaseFactory {
  static Future<DatabaseExecutor> createDatabase() async {
    try {
      if (kIsWeb) {
        // On Flutter Web, use InMemoryDatabaseExecutor (or sqlite3 wasm if configured)
        return InMemoryDatabaseExecutor();
      } else {
        // Desktop / Windows / Native
        final db = sql.sqlite3.openInMemory();
        return Sqlite3Executor(db);
      }
    } catch (e) {
      debugPrint('Database initialization fallback: $e');
      return InMemoryDatabaseExecutor();
    }
  }
}
