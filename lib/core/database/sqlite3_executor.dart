import 'package:sqlite3/sqlite3.dart' as sql;
import 'database_executor.dart';

DatabaseExecutor createNativeDatabase() {
  final db = sql.sqlite3.openInMemory();
  return Sqlite3Executor(db);
}

class Sqlite3Executor implements DatabaseExecutor {
  final sql.Database _db;

  Sqlite3Executor(this._db);

  @override
  Future<void> execute(String sqlQuery, [List<Object?> parameters = const []]) async {
    if (parameters.isEmpty) {
      _db.execute(sqlQuery);
    } else {
      final stmt = _db.prepare(sqlQuery);
      try {
        stmt.execute(parameters);
      } finally {
        stmt.dispose();
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sqlQuery, [List<Object?> parameters = const []]) async {
    final stmt = _db.prepare(sqlQuery);
    try {
      final sql.ResultSet result = stmt.select(parameters);
      final List<Map<String, dynamic>> list = [];
      for (final row in result) {
        final map = <String, dynamic>{};
        for (final col in result.columnNames) {
          map[col] = row[col];
        }
        list.add(map);
      }
      return list;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sqlQuery = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    final stmt = _db.prepare(sqlQuery);
    try {
      stmt.execute(values.values.toList());
      return _db.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> insertBatch(String table, List<Map<String, dynamic>> rowsList) async {
    if (rowsList.isEmpty) return 0;
    int count = 0;
    for (final values in rowsList) {
      await insert(table, values);
      count++;
    }
    return count;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final setClause = values.keys.map((k) => '$k = ?').join(', ');
    var sqlQuery = 'UPDATE $table SET $setClause';
    final params = List<Object?>.from(values.values);
    if (where != null) {
      sqlQuery += ' WHERE $where';
      if (whereArgs != null) {
        params.addAll(whereArgs);
      }
    }
    final stmt = _db.prepare(sqlQuery);
    try {
      stmt.execute(params);
      return _db.getUpdatedRows();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    var sqlQuery = 'DELETE FROM $table';
    final params = <Object?>[];
    if (where != null) {
      sqlQuery += ' WHERE $where';
      if (whereArgs != null) {
        params.addAll(whereArgs);
      }
    }
    final stmt = _db.prepare(sqlQuery);
    try {
      stmt.execute(params);
      return _db.getUpdatedRows();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> close() async {
    _db.dispose();
  }
}
