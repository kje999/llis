abstract class DatabaseExecutor {
  Future<void> execute(String sql, [List<Object?> parameters = const []]);
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> parameters = const []]);
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Future<void> close();
}

abstract class AppDatabase {
  Future<DatabaseExecutor> init();
  DatabaseExecutor get db;
}
