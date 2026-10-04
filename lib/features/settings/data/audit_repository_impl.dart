import '../../../core/database/database_executor.dart';
import '../../../shared/models/audit_log.dart';
import '../domain/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  final DatabaseExecutor _db;

  AuditRepositoryImpl(this._db);

  @override
  Future<List<AuditLog>> getAll({int limit = 100}) async {
    final rows = await _db.query('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT ?', [limit]);
    return rows.map((r) => AuditLog.fromMap(r)).toList();
  }

  @override
  Future<int> insert(AuditLog log) async {
    final map = log.toMap()..remove('id');
    return await _db.insert('audit_logs', map);
  }
}
