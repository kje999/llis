import 'package:my_lucky_lotto_pred/shared/models/in_app_notification.dart';

abstract class NotificationRepository {
  Future<List<InAppNotification>> getByUserId(int userId, {int limit = 50});
  Future<int> insert(InAppNotification notification);
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead(int userId);
  Future<int> getUnreadCount(int userId);
}
