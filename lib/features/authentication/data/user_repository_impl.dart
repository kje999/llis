import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/user.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseExecutor _db;

  UserRepositoryImpl(this._db);

  @override
  Future<List<User>> getAllUsers() async {
    final rows = await _db.query('SELECT * FROM users ORDER BY id ASC');
    return rows.map((r) => User.fromMap(r)).toList();
  }

  @override
  Future<User?> getById(int id) async {
    final rows = await _db.query('SELECT * FROM users WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  @override
  Future<User?> getByUsername(String username) async {
    final rows = await _db.query('SELECT * FROM users WHERE LOWER(username) = ?', [username.toLowerCase()]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  @override
  Future<int> insertUser(User user) async {
    final map = user.toMap()..remove('id');
    final id = await _db.insert('users', map);

    // Sync to backend central SQLite database
    try {
      await http.post(
        Uri.parse('http://localhost:8081/api/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toMap()),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}

    return id;
  }

  @override
  Future<void> updateUser(User user) async {
    await _db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  @override
  Future<void> updatePassword(int userId, String newHash) async {
    await _db.update(
      'users',
      {
        'password_hash': newHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> deactivateUser(int userId) async {
    await _db.update(
      'users',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> deleteUser(int userId) async {
    await _db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> countAdminUsers() async {
    final rows = await _db.query("SELECT COUNT(*) as count FROM users WHERE role = 'ADMIN' AND is_active = 1");
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 1;
  }
}
