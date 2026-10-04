import 'package:my_lucky_lotto_pred/shared/models/audit_log.dart';

abstract class AuditRepository {
  Future<List<AuditLog>> getAll({int limit = 100});
  Future<int> insert(AuditLog log);
}
