import '../../../core/database/database_executor.dart';
import '../../../shared/models/prediction_history.dart';
import '../domain/prediction_repository.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  final DatabaseExecutor _db;

  PredictionRepositoryImpl(this._db);

  @override
  Future<List<PredictionHistory>> getByLottoTypeId(int lottoTypeId, {int limit = 10}) async {
    const sql = '''
      SELECT h.*, t.name as lotto_type_name
      FROM prediction_history h
      JOIN lotto_types t ON h.lotto_type_id = t.id
      WHERE h.lotto_type_id = ?
      ORDER BY h.created_at DESC
      LIMIT ?
    ''';
    final rows = await _db.query(sql, [lottoTypeId, limit]);
    return rows.map((r) => PredictionHistory.fromMap(r)).toList();
  }

  @override
  Future<int> insert(PredictionHistory history) async {
    final map = history.toMap()..remove('id');
    return await _db.insert('prediction_history', map);
  }
}
