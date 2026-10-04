import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/synchronization_log.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_repository.dart';

class SynchronizationRepositoryImpl implements SynchronizationRepository {
  final DatabaseExecutor _db;

  SynchronizationRepositoryImpl(this._db);

  @override
  Future<List<SynchronizationLog>> getAllLogs({int limit = 50}) async {
    final rows = await _db.query(
      'SELECT * FROM synchronization_logs ORDER BY started_at DESC LIMIT ?',
      [limit],
    );
    return rows.map((r) => SynchronizationLog.fromMap(r)).toList();
  }

  @override
  Future<SynchronizationLog?> getLatestLog() async {
    final rows = await _db.query('SELECT * FROM synchronization_logs ORDER BY started_at DESC LIMIT 1');
    if (rows.isEmpty) return null;
    return SynchronizationLog.fromMap(rows.first);
  }

  @override
  Future<int> insertLog(SynchronizationLog log) async {
    final map = log.toMap()..remove('id');
    return await _db.insert('synchronization_logs', map);
  }

  @override
  Future<int> getFailureCount() async {
    final rows = await _db.query("SELECT COUNT(*) as count FROM synchronization_logs WHERE status = 'FAILED'");
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }
}
