class AuditLog {
  final int id;
  final int? userId;
  final String action;
  final String entityType;
  final int? entityId;
  final String description;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.description,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as int,
      userId: map['user_id'] as int?,
      action: map['action'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int?,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
