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
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as int) == 1,
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
