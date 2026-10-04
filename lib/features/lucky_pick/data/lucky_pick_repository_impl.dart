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
    return await _db.insert('lucky_picks', map);
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
