import 'package:my_lucky_lotto_pred/shared/models/synchronization_log.dart';

abstract class SynchronizationRepository {
  Future<List<SynchronizationLog>> getAllLogs({int limit = 50});
  Future<SynchronizationLog?> getLatestLog();
  Future<int> insertLog(SynchronizationLog log);
  Future<int> getFailureCount();
}
