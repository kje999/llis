import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/core/constants/api_constants.dart';
import 'package:my_lucky_lotto_pred/core/database/database_executor.dart';
import 'package:my_lucky_lotto_pred/shared/models/user.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseExecutor _db;

  UserRepositoryImpl(this._db);

  @override
  Future<List<User>> getAllUsers() async {
    var rows = await _db.query('SELECT * FROM users ORDER BY id ASC');
    if (rows.isEmpty) {
      await syncUsersFromBackend();
      rows = await _db.query('SELECT * FROM users ORDER BY id ASC');
    }
    return rows.map((r) => User.fromMap(r)).toList();
  }

  @override
  Future<User?> getById(int id) async {
    var rows = await _db.query('SELECT * FROM users WHERE id = ?', [id]);
    if (rows.isEmpty) {
      await syncUsersFromBackend();
      rows = await _db.query('SELECT * FROM users WHERE id = ?', [id]);
    }
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  @override
  Future<User?> getByUsername(String username) async {
    var rows = await _db.query('SELECT * FROM users WHERE LOWER(username) = ?', [username.toLowerCase()]);
    if (rows.isEmpty) {
      await syncUsersFromBackend();
      rows = await _db.query('SELECT * FROM users WHERE LOWER(username) = ?', [username.toLowerCase()]);
    }
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  /// Synchronizes real persistent user accounts from the central SQLite backend
  Future<void> syncUsersFromBackend() async {
    try {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final urls = [
        ApiConstants.usersEndpoint,
        'http://$host:8081/api/users',
        'http://localhost:8081/api/users',
        'http://127.0.0.1:8081/api/users',
      ];
      http.Response? res;
      for (final u in urls) {
        try {
          final r = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 2));
          if (r.statusCode == 200) {
            res = r;
            break;
          }
        } catch (_) {}
      }
      if (res != null && res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List) {
          // Remove legacy seeded test accounts if present in memory
          await _db.delete('users', where: "LOWER(username) = 'kenth'");

          for (final u in list) {
            final userMap = Map<String, dynamic>.from(u);
            final uname = userMap['username']?.toString() ?? '';
            if (uname.isEmpty) continue;
            final uId = (userMap['id'] as num?)?.toInt();
            final existing = await _db.query(
              'SELECT id FROM users WHERE LOWER(username) = ?',
              [uname.toLowerCase()],
            );
            if (existing.isEmpty) {
              await _db.insert('users', {
                if (uId != null) 'id': uId,
                'username': uname,
                'password_hash': userMap['password_hash'] ?? '',
                'role': userMap['role'] ?? 'CLIENT',
                'full_name': userMap['full_name'] ?? uname,
                'email': userMap['email'] ?? '',
                'created_at': userMap['created_at'] ?? DateTime.now().toIso8601String(),
                'updated_at': userMap['updated_at'] ?? DateTime.now().toIso8601String(),
                'is_active': (userMap['is_active'] == 1 || userMap['is_active'] == true) ? 1 : 0,
              });
            } else {
              await _db.update(
                'users',
                {
                  if (uId != null) 'id': uId,
                  'password_hash': userMap['password_hash'] ?? '',
                  'role': userMap['role'] ?? 'CLIENT',
                  'full_name': userMap['full_name'] ?? uname,
                  'email': userMap['email'] ?? '',
                  'is_active': (userMap['is_active'] == 1 || userMap['is_active'] == true) ? 1 : 0,
                },
                where: 'id = ?',
                whereArgs: [existing.first['id']],
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<int> insertUser(User user) async {
    final map = user.toMap()..remove('id');
    final id = await _db.insert('users', map);

    // Sync to backend central SQLite database
    try {
      await http.post(
        Uri.parse(ApiConstants.userSyncEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toMap()),
      ).timeout(const Duration(seconds: 3));
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
