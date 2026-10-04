import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/lucky_pick.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';

class LuckyPickRepositoryImpl implements LuckyPickRepository {
  final DatabaseExecutor _db;

  LuckyPickRepositoryImpl(this._db);

  @override
  Future<List<LuckyPick>> getByUserId(int userId) async {
    const sql = '''
      SELECT p.*, t.name as lotto_type_name, t.code as lotto_type_code
      FROM lucky_picks p
      JOIN lotto_types t ON p.lotto_type_id = t.id
      WHERE p.user_id = ?
      ORDER BY p.generated_at DESC
    ''';
    final rows = await _db.query(sql, [userId]);
    return rows.map((r) => LuckyPick.fromMap(r)).toList();
  }

  @override
  Future<List<LuckyPick>> getUncheckedPicks(int lottoTypeId, String drawDate) async {
    const sql = '''
      SELECT p.*, t.name as lotto_type_name, t.code as lotto_type_code
      FROM lucky_picks p
      JOIN lotto_types t ON p.lotto_type_id = t.id
      WHERE p.lotto_type_id = ? AND p.draw_date = ? AND p.is_checked = 0
    ''';
    final rows = await _db.query(sql, [lottoTypeId, drawDate]);
    return rows.map((r) => LuckyPick.fromMap(r)).toList();
  }

  @override
  Future<int> insert(LuckyPick pick) async {
    final map = pick.toMap()..remove('id');
    final id = await _db.insert('lucky_picks', map);

    // Sync to backend central SQLite database
    try {
      await http.post(
        Uri.parse('http://localhost:8081/api/picks/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': pick.userId,
          'lotto_type_id': pick.lottoTypeId,
          'draw_date': pick.drawDate,
          'numbers': pick.numbers,
          'is_checked': pick.isChecked,
          'match_count': pick.matchCount,
          'status': pick.status,
        }),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}

    return id;
  }

  @override
  Future<void> update(LuckyPick pick) async {
    await _db.update(
      'lucky_picks',
      pick.toMap(),
      where: 'id = ?',
      whereArgs: [pick.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('lucky_picks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getTotalCount() async {
    final rows = await _db.query('SELECT COUNT(*) as count FROM lucky_picks');
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }
}
