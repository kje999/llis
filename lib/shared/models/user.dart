class User {
  final int id;
  final String username;
  final String passwordHash;
  final String role; // 'CLIENT' or 'ADMIN'
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isClient => role == 'CLIENT';

  factory User.fromMap(Map<String, dynamic> map) {
    final rawIsActive = map['is_active'];
    final bool active = rawIsActive == 1 || rawIsActive == true || rawIsActive == '1';

    DateTime parseDate(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return User(
      id: (map['id'] as num?)?.toInt() ?? 0,
      username: (map['username'] ?? '').toString(),
      passwordHash: (map['password_hash'] ?? '').toString(),
      role: (map['role'] ?? 'CLIENT').toString(),
      fullName: (map['full_name'] ?? map['username'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      isActive: active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
      'full_name': fullName,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }
}
