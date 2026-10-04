import '../../../core/database/database_executor.dart';
import '../../../shared/models/lotto_type.dart';
import 'lotto_type_repository.dart';

class LottoTypeRepositoryImpl implements LottoTypeRepository {
  final DatabaseExecutor _db;

  LottoTypeRepositoryImpl(this._db);

  @override
  Future<List<LottoType>> getAll() async {
    final rows = await _db.query('SELECT * FROM lotto_types WHERE is_active = 1 ORDER BY id ASC');
    return rows.map((r) => LottoType.fromMap(r)).toList();
  }

  @override
  Future<LottoType?> getById(int id) async {
    final rows = await _db.query('SELECT * FROM lotto_types WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return LottoType.fromMap(rows.first);
  }

  @override
  Future<LottoType?> getByCode(String code) async {
    final rows = await _db.query('SELECT * FROM lotto_types WHERE code = ?', [code]);
    if (rows.isEmpty) return null;
    return LottoType.fromMap(rows.first);
  }
}
