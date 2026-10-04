import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/notifications/domain/notification_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/in_app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<InAppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    final repo = context.read<NotificationRepository>();
    final list = await repo.getByUserId(auth.currentUser!.id);

    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;

    final repo = context.read<NotificationRepository>();
    await repo.markAllAsRead(auth.currentUser!.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications & Alerts',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text('Winning alerts, draw match updates, and synchronization logs.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                ],
              ),
              if (_notifications.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark All Read'),
                  onPressed: _markAllRead,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_notifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No notifications right now.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Card(
                  elevation: notif.isRead ? 0 : 2,
                  color: notif.isRead ? Colors.white : Colors.blue.shade50.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: notif.isRead ? Colors.grey.shade200 : Colors.blue.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: _getCategoryIcon(notif.category),
                    title: Text(
                      notif.title,
                      style: TextStyle(fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.message),
                        const SizedBox(height: 6),
                        Text(
                          notif.createdAt.toLocal().toString().substring(0, 16),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    trailing: notif.isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.check, size: 18),
                            tooltip: 'Mark as read',
                            onPressed: () async {
                              await context.read<NotificationRepository>().markAsRead(notif.id);
                              _loadNotifications();
                            },
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String cat) {
    switch (cat) {
      case 'MATCH_FOUND':
        return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.military_tech, color: Colors.white, size: 20));
      case 'LUCKY_PICK_CHECKED':
        return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.done, color: Colors.white, size: 20));
      case 'SYNC_COMPLETED':
        return const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.sync, color: Colors.white, size: 20));
      default:
        return const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.notifications, color: Colors.white, size: 20));
    }
  }
}
