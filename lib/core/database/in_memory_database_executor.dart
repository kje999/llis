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
    final cleanSql = sql.replaceAll('\n', ' ').trim();

    // Handle COUNT(*) queries
    final countMatch = RegExp(r'SELECT\s+COUNT\(\*\)\s+as\s+(\w+)\s+FROM\s+(\w+)', caseSensitive: false).firstMatch(cleanSql);
    if (countMatch != null) {
      final alias = countMatch.group(1)!;
      final tableName = countMatch.group(2)!;
      var rows = _tables[tableName] ?? [];
      rows = _applyWhere(rows, cleanSql, parameters);
      return [{alias: rows.length}];
    }

    // Find table name
    final matches = RegExp(r'FROM\s+([a-zA-Z0-9_]+)', caseSensitive: false).firstMatch(cleanSql);
    if (matches == null) return [];

    final tableName = matches.group(1)!;
    var rows = List<Map<String, dynamic>>.from(_tables[tableName] ?? []);

    // Handle JOIN lotto_types
    if (cleanSql.toUpperCase().contains('JOIN LOTTO_TYPES')) {
      final types = _tables['lotto_types'] ?? [];
      final typeMap = {for (var t in types) t['id']: t};

      rows = rows.map((r) {
        final merged = Map<String, dynamic>.from(r);
        final lottoTypeId = r['lotto_type_id'];
        if (lottoTypeId != null && typeMap.containsKey(lottoTypeId)) {
          final t = typeMap[lottoTypeId]!;
          merged['lotto_type_name'] = t['name'];
          merged['lotto_type_code'] = t['code'];
        }
        return merged;
      }).toList();
    }

    // Apply WHERE conditions
    rows = _applyWhere(rows, cleanSql, parameters);

    // Apply ORDER BY
    final orderMatch = RegExp(r'ORDER\s+BY\s+([a-zA-Z0-9_.]+)(?:\s+(ASC|DESC))?', caseSensitive: false).firstMatch(cleanSql);
    if (orderMatch != null) {
      var col = orderMatch.group(1)!;
      if (col.contains('.')) col = col.split('.').last;
      final isDesc = (orderMatch.group(2) ?? 'ASC').toUpperCase() == 'DESC';

      rows.sort((a, b) {
        final valA = a[col];
        final valB = b[col];
        if (valA == null && valB == null) return 0;
        if (valA == null) return isDesc ? 1 : -1;
        if (valB == null) return isDesc ? -1 : 1;
        final comp = Comparable.compare(valA as Comparable, valB as Comparable);
        if (comp != 0) {
          return isDesc ? -comp : comp;
        }
        // Tie-breaker: sort by lotto_type_id ASC so Ultra 6/58, Grand 6/55, Super 6/49 display consistently
        final typeA = a['lotto_type_id'];
        final typeB = b['lotto_type_id'];
        if (typeA is Comparable && typeB is Comparable) {
          return Comparable.compare(typeA, typeB);
        }
        return 0;
      });
    }

    // Apply LIMIT and OFFSET
    int? limit;
    int? offset;

    final limitMatch = RegExp(r'LIMIT\s+(\?|\d+)(?:\s+OFFSET\s+(\?|\d+))?', caseSensitive: false).firstMatch(cleanSql);
    if (limitMatch != null) {
      final limitToken = limitMatch.group(1)!;
      int limitParamIdx = -1;
      if (limitToken == '?') {
        limitParamIdx = RegExp(r'\?').allMatches(cleanSql.substring(0, limitMatch.start)).length;
        if (limitParamIdx < parameters.length) {
          limit = parameters[limitParamIdx] as int?;
        }
      } else {
        limit = int.tryParse(limitToken);
      }

      final offsetToken = limitMatch.group(2);
      if (offsetToken != null) {
        if (offsetToken == '?') {
          final offsetParamIdx = limitParamIdx >= 0
              ? limitParamIdx + 1
              : RegExp(r'\?').allMatches(cleanSql.substring(0, limitMatch.start + (limitMatch.group(0)?.indexOf('OFFSET') ?? 0))).length;
          if (offsetParamIdx < parameters.length) {
            offset = parameters[offsetParamIdx] as int?;
          }
        } else {
          offset = int.tryParse(offsetToken);
        }
      }
    }

    final start = offset ?? 0;
    if (start > 0) {
      if (start >= rows.length) return [];
      rows = rows.sublist(start);
    }

    if (limit != null && limit > 0 && rows.length > limit) {
      rows = rows.sublist(0, limit);
    }

    return rows.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  List<Map<String, dynamic>> _applyWhere(
    List<Map<String, dynamic>> rows,
    String sql,
    List<Object?> params,
  ) {
    var result = List<Map<String, dynamic>>.from(rows);

    // WHERE id = ?
    if (RegExp(r'(?:WHERE|\bAND)\s+(?:\w+\.)?id\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      if (params.isNotEmpty && params.first is int) {
        final targetId = params.first as int;
        return result.where((r) => r['id'] == targetId).toList();
      }
    }

    // WHERE LOWER(username) = ? or username = ?
    if (RegExp(r'(?:LOWER\(username\)|username)\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      if (params.isNotEmpty && params.first != null) {
        final targetUser = params.first.toString().toLowerCase().trim();
        return result.where((r) => (r['username']?.toString().toLowerCase().trim() ?? '') == targetUser).toList();
      }
    }

    // WHERE code = ?
    if (RegExp(r'\bcode\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      if (params.isNotEmpty && params.first != null) {
        final targetCode = params.first.toString().trim();
        return result.where((r) => r['code'] == targetCode).toList();
      }
    }

    // WHERE user_id = ?
    if (RegExp(r'\buser_id\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      if (params.isNotEmpty && params.first is int) {
        final targetUserId = params.first as int;
        result = result.where((r) => r['user_id'] == targetUserId).toList();
      }
    }

    // WHERE lotto_type_id = ?
    if (RegExp(r'(?:\w+\.)?lotto_type_id\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      final paramIdx = RegExp(r'\?').allMatches(sql.split('lotto_type_id').first).length;
      if (paramIdx < params.length && params[paramIdx] is int) {
        final typeId = params[paramIdx] as int;
        result = result.where((r) => r['lotto_type_id'] == typeId).toList();
      }
    }

    // WHERE draw_date = ?
    if (RegExp(r'(?:\w+\.)?draw_date\s*=\s*\?', caseSensitive: false).hasMatch(sql)) {
      final paramIdx = RegExp(r'\?').allMatches(sql.split('draw_date').first).length;
      if (paramIdx < params.length && params[paramIdx] != null) {
        final date = params[paramIdx].toString().trim();
        result = result.where((r) => r['draw_date'] == date).toList();
      }
    }

    // WHERE draw_date >= ? AND draw_date <= ?
    if (RegExp(r'draw_date\s*>=\s*\?\s+AND\s+draw_date\s*<=\s*\?', caseSensitive: false).hasMatch(sql)) {
      String? start;
      String? end;
      for (final p in params) {
        if (p is String && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(p)) {
          if (start == null) {
            start = p;
          } else if (end == null) {
            end = p;
          }
        }
      }
      if (start != null && end != null) {
        result = result.where((r) {
          final d = r['draw_date']?.toString() ?? '';
          return d.compareTo(start!) >= 0 && d.compareTo(end!) <= 0;
        }).toList();
      }
    }

    // WHERE draw_date >= '...'
    final gteDateMatch = RegExp(r'draw_date\s*>=\s*[\x27"]([^\x27"]+)[\x27"]', caseSensitive: false).firstMatch(sql);
    if (gteDateMatch != null) {
      final targetDate = gteDateMatch.group(1)!;
      result = result.where((r) {
        final d = r['draw_date']?.toString() ?? '';
        return d.compareTo(targetDate) >= 0;
      }).toList();
    }

    // IS_ACTIVE = 1
    if (sql.toUpperCase().contains('IS_ACTIVE = 1')) {
      result = result.where((r) => r['is_active'] == 1 || r['is_active'] == true).toList();
    }

    // IS_CHECKED = 0
    if (sql.toUpperCase().contains('IS_CHECKED = 0')) {
      result = result.where((r) => r['is_checked'] == 0 || r['is_checked'] == false).toList();
    }

    // ROLE = 'ADMIN'
    if (sql.toUpperCase().contains("ROLE = 'ADMIN'")) {
      result = result.where((r) => r['role'] == 'ADMIN').toList();
    }

    return result;
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
