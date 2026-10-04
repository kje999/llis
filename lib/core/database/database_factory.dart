import 'package:flutter/foundation.dart';
import 'database_executor.dart';
import 'in_memory_database_executor.dart';
import 'sqlite3_stub.dart' if (dart.library.io) 'sqlite3_executor.dart';

class DatabaseFactory {
  static Future<DatabaseExecutor> createDatabase() async {
    try {
      if (kIsWeb) {
        // On Flutter Web, use InMemoryDatabaseExecutor (WASM browser storage)
        return InMemoryDatabaseExecutor();
      } else {
        // Desktop / Windows / Native
        return createNativeDatabase();
      }
    } catch (e) {
      debugPrint('Database initialization fallback: $e');
      return InMemoryDatabaseExecutor();
    }
  }
}
