class InAppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String category; // 'RESULT_AVAILABLE', 'LUCKY_PICK_CHECKED', 'MATCH_FOUND', 'SYNC_COMPLETED', 'SYNC_FAILED', 'SYSTEM'
  final bool isRead;
  final DateTime createdAt;

  InAppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.category,
    this.isRead = false,
    required this.createdAt,
  });

  factory InAppNotification.fromMap(Map<String, dynamic> map) {
    return InAppNotification(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      category: map['category'] as String,
      isRead: (map['is_read'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'category': category,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
