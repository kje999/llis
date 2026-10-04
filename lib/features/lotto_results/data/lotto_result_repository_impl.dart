import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';

class LottoResultRepositoryImpl implements LottoResultRepository {
  final DatabaseExecutor _db;

  LottoResultRepositoryImpl(this._db);

  @override
  Future<List<LottoResult>> getAll({int limit = 50, int offset = 0, int? lottoTypeId}) async {
    String sql = '''
      SELECT r.*, t.name as lotto_type_name 
      FROM lotto_results r
      JOIN lotto_types t ON r.lotto_type_id = t.id
    ''';
    final params = <Object?>[];

    if (lottoTypeId != null) {
      sql += ' WHERE r.lotto_type_id = ?';
      params.add(lottoTypeId);
    }

    sql += ' ORDER BY r.draw_date DESC LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    final rows = await _db.query(sql, params);
    return rows.map((r) => LottoResult.fromMap(r)).toList();
  }

  @override
  Future<List<LottoResult>> getByDateRange({
    required int lottoTypeId,
    required String startDate,
    required String endDate,
  }) async {
    const sql = '''
      SELECT r.*, t.name as lotto_type_name
      FROM lotto_results r
      JOIN lotto_types t ON r.lotto_type_id = t.id
      WHERE r.lotto_type_id = ? AND r.draw_date >= ? AND r.draw_date <= ?
      ORDER BY r.draw_date ASC
    ''';
    final rows = await _db.query(sql, [lottoTypeId, startDate, endDate]);
    return rows.map((r) => LottoResult.fromMap(r)).toList();
  }

  @override
  Future<LottoResult?> getById(int id) async {
    const sql = '''
      SELECT r.*, t.name as lotto_type_name
      FROM lotto_results r
      JOIN lotto_types t ON r.lotto_type_id = t.id
      WHERE r.id = ?
    ''';
    final rows = await _db.query(sql, [id]);
    if (rows.isEmpty) return null;
    return LottoResult.fromMap(rows.first);
  }

  @override
  Future<LottoResult?> getLatestByTypeId(int lottoTypeId) async {
    const sql = '''
      SELECT r.*, t.name as lotto_type_name
      FROM lotto_results r
      JOIN lotto_types t ON r.lotto_type_id = t.id
      WHERE r.lotto_type_id = ?
      ORDER BY r.draw_date DESC
      LIMIT 1
    ''';
    final rows = await _db.query(sql, [lottoTypeId]);
    if (rows.isEmpty) return null;
    return LottoResult.fromMap(rows.first);
  }

  @override
  Future<LottoResult?> findExisting(int lottoTypeId, String drawDate) async {
    final rows = await _db.query(
      'SELECT * FROM lotto_results WHERE lotto_type_id = ? AND draw_date = ?',
      [lottoTypeId, drawDate],
    );
    if (rows.isEmpty) return null;
    return LottoResult.fromMap(rows.first);
  }

  @override
  Future<int> insert(LottoResult result) async {
    final map = result.toMap()..remove('id');
    return await _db.insert('lotto_results', map);
  }

  @override
  Future<void> update(LottoResult result) async {
    await _db.update(
      'lotto_results',
      result.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('lotto_results', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getTotalCount() async {
    final rows = await _db.query('SELECT COUNT(*) as count FROM lotto_results');
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }

  @override
  Future<int> getCountThisYear() async {
    final currentYear = DateTime.now().year.toString();
    final rows = await _db.query(
      "SELECT COUNT(*) as count FROM lotto_results WHERE draw_date >= '$currentYear-01-01'",
    );
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }
}
