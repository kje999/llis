import '../../../shared/models/audit_log.dart';

abstract class AuditRepository {
  Future<List<AuditLog>> getAll({int limit = 100});
  Future<int> insert(AuditLog log);
}
