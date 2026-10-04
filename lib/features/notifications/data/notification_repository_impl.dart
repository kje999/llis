import '../../../core/database/database_executor.dart';
import '../../../shared/models/in_app_notification.dart';
import '../domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DatabaseExecutor _db;

  NotificationRepositoryImpl(this._db);

  @override
  Future<List<InAppNotification>> getByUserId(int userId, {int limit = 50}) async {
    final rows = await _db.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
      [userId, limit],
    );
    return rows.map((r) => InAppNotification.fromMap(r)).toList();
  }

  @override
  Future<int> insert(InAppNotification notification) async {
    final map = notification.toMap()..remove('id');
    return await _db.insert('notifications', map);
  }

  @override
  Future<void> markAsRead(int id) async {
    await _db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> markAllAsRead(int userId) async {
    await _db.update('notifications', {'is_read': 1}, where: 'user_id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final rows = await _db.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }
}
