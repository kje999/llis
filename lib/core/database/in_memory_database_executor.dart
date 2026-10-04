import 'database_executor.dart';

class InMemoryDatabaseExecutor implements DatabaseExecutor {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  int _lastId = 100;

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const []]) async {
    // Basic table tracker for DDL
    final trimmed = sql.trim().toUpperCase();
    if (trimmed.startsWith('CREATE TABLE')) {
      final parts = sql.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final tableName = parts[2].replaceAll('(', '').replaceAll('"', '').replaceAll('`', '');
        _tables.putIfAbsent(tableName, () => []);
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> parameters = const []]) async {
    // Parse table name from simple SELECT queries
    final matches = RegExp(r'FROM\s+([a-zA-Z0-9_]+)', caseSensitive: false).firstMatch(sql);
    if (matches != null) {
      final tableName = matches.group(1)!;
      final list = _tables[tableName] ?? [];
      // Return cloned items
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    _tables.putIfAbsent(table, () => []);
    final record = Map<String, dynamic>.from(values);
    _lastId++;
    if (!record.containsKey('id') || record['id'] == null) {
      record['id'] = _lastId;
    }
    _tables[table]!.add(record);
    return record['id'] as int;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final list = _tables[table] ?? [];
    int count = 0;
    for (final item in list) {
      if (where != null && where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
        if (item['id'] == whereArgs.first) {
          item.addAll(values);
          count++;
        }
      } else {
        item.addAll(values);
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = _tables[table] ?? [];
    final initialLength = list.length;
    if (where != null && where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      list.removeWhere((item) => item['id'] == whereArgs.first);
    } else {
      list.clear();
    }
    return initialLength - list.length;
  }

  @override
  Future<void> close() async {
    _tables.clear();
  }
}
