import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_lucky_lotto_pred/core/security/password_hasher.dart';
import 'package:my_lucky_lotto_pred/shared/models/user.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';

import 'package:my_lucky_lotto_pred/core/storage/session_storage.dart';

class AuthService extends ChangeNotifier {
  static const String _prefUserId = 'auth_session_user_id';
  static const String _prefUsername = 'auth_session_username';
  static const String _prefToken = 'auth_session_token';
  static const String _prefExpiresAt = 'auth_session_expires_at';
  static const String _prefUserData = 'auth_session_user_data';

  final UserRepository _userRepo;
  User? _currentUser;
  String? _sessionToken;
  bool _mustChangeAdminPassword = false;
  bool _isInitialized = false;

  AuthService(this._userRepo) {
    _restoreSession();
  }

  User? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get mustChangeAdminPassword => _mustChangeAdminPassword;
  bool get isInitialized => _isInitialized;

  String _generateToken(User user) {
    final raw = '${user.id}:${user.username}:${DateTime.now().millisecondsSinceEpoch}:${user.passwordHash.hashCode}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Future<void> _saveSession(User user) async {
    _sessionToken = _generateToken(user);
    final expiresAt = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
    final userJson = jsonEncode(user.toMap());

    // 1. Direct Web localStorage persistence (Instant & 100% resilient on web reloads)
    WebSessionStorage.setItem(_prefUserId, user.id.toString());
    WebSessionStorage.setItem(_prefUsername, user.username);
    WebSessionStorage.setItem(_prefToken, _sessionToken!);
    WebSessionStorage.setItem(_prefExpiresAt, expiresAt.toString());
    WebSessionStorage.setItem(_prefUserData, userJson);

    // 2. SharedPreferences persistence (Cross-platform)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserId, user.id);
      await prefs.setString(_prefUsername, user.username);
      await prefs.setString(_prefToken, _sessionToken!);
      await prefs.setInt(_prefExpiresAt, expiresAt);
      await prefs.setString(_prefUserData, userJson);
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    _sessionToken = null;
    _currentUser = null;
    WebSessionStorage.removeItem(_prefUserId);
    WebSessionStorage.removeItem(_prefUsername);
    WebSessionStorage.removeItem(_prefToken);
    WebSessionStorage.removeItem(_prefExpiresAt);
    WebSessionStorage.removeItem(_prefUserData);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserId);
      await prefs.remove(_prefUsername);
      await prefs.remove(_prefToken);
      await prefs.remove(_prefExpiresAt);
      await prefs.remove(_prefUserData);
    } catch (_) {}
  }

  Future<void> _restoreSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Fast Path: Immediate check from WebSessionStorage (instant local storage)
    try {
      final webToken = WebSessionStorage.getItem(_prefToken);
      final webUserData = WebSessionStorage.getItem(_prefUserData);
      final webExpiresStr = WebSessionStorage.getItem(_prefExpiresAt);
      final webExpiresAt = webExpiresStr != null ? int.tryParse(webExpiresStr) : null;

      if (webToken != null &&
          (webExpiresAt == null || webExpiresAt > now) &&
          webUserData != null &&
          webUserData.isNotEmpty) {
        final map = jsonDecode(webUserData) as Map<String, dynamic>;
        final user = User.fromMap(map);
        if (user.isActive) {
          _currentUser = user;
          _sessionToken = webToken;
          if (user.username.toUpperCase() == 'ADMIN' &&
              PasswordHasher.verify('ADMIN', user.passwordHash)) {
            _mustChangeAdminPassword = true;
          } else {
            _mustChangeAdminPassword = false;
          }
          _isInitialized = true;
          notifyListeners();

          // Sync into database in background without blocking UI
          _ensureUserInDatabase(user);
          return;
        }
      }
    } catch (_) {}

    // Fallback Path: Check SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefToken);
      final expiresAt = prefs.getInt(_prefExpiresAt);
      final userDataJson = prefs.getString(_prefUserData);
      final userId = prefs.getInt(_prefUserId);
      final username = prefs.getString(_prefUsername);

      if (token != null && (expiresAt == null || expiresAt > now)) {
        User? user;
        if (userDataJson != null && userDataJson.isNotEmpty) {
          try {
            final map = jsonDecode(userDataJson) as Map<String, dynamic>;
            user = User.fromMap(map);
          } catch (_) {}
        }

        if (user == null) {
          if (userId != null) {
            user = await _userRepo.getById(userId);
          }
          if (user == null && username != null && username.isNotEmpty) {
            user = await _userRepo.getByUsername(username);
          }
        }

        if (user != null && user.isActive) {
          _currentUser = user;
          _sessionToken = token;
          if (user.username.toUpperCase() == 'ADMIN' &&
              PasswordHasher.verify('ADMIN', user.passwordHash)) {
            _mustChangeAdminPassword = true;
          } else {
            _mustChangeAdminPassword = false;
          }
          // Back-propagate to WebSessionStorage
          WebSessionStorage.setItem(_prefToken, token);
          WebSessionStorage.setItem(_prefExpiresAt, (expiresAt ?? (now + 30 * 86400000)).toString());
          WebSessionStorage.setItem(_prefUserData, jsonEncode(user.toMap()));

          _ensureUserInDatabase(user);
        } else if (expiresAt != null && expiresAt <= now) {
          await _clearSession();
        }
      } else if (token != null && expiresAt != null && expiresAt <= now) {
        await _clearSession();
      }
    } catch (_) {}

    _isInitialized = true;
    notifyListeners();
  }

  void _ensureUserInDatabase(User user) {
    Future.microtask(() async {
      try {
        final existing = await _userRepo.getByUsername(user.username);
        if (existing == null) {
          await _userRepo.insertUser(user);
        }
      } catch (_) {}
    });
  }

  Future<bool> login(String username, String password) async {
    final user = await _userRepo.getByUsername(username.trim());
    if (user == null || !user.isActive) {
      return false;
    }

    final isValid = PasswordHasher.verify(password, user.passwordHash);
    if (!isValid) return false;

    _currentUser = user;
    await _saveSession(user);

    // Check if it's default ADMIN with default password
    if (user.username.toUpperCase() == 'ADMIN' &&
        PasswordHasher.verify('ADMIN', user.passwordHash)) {
      _mustChangeAdminPassword = true;
    } else {
      _mustChangeAdminPassword = false;
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _mustChangeAdminPassword = false;
    await _clearSession();
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final existing = await _userRepo.getByUsername(username.trim());
    if (existing != null) return false;

    final now = DateTime.now();
    final newUser = User(
      id: 0,
      username: username.trim(),
      passwordHash: PasswordHasher.hash(password),
      role: 'CLIENT',
      fullName: fullName.trim(),
      email: email.trim(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    final id = await _userRepo.insertUser(newUser);
    if (id > 0) {
      _currentUser = await _userRepo.getById(id);
      if (_currentUser != null) {
        await _saveSession(_currentUser!);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;
    if (!PasswordHasher.verify(oldPassword, _currentUser!.passwordHash)) {
      return false;
    }

    final newHash = PasswordHasher.hash(newPassword);
    await _userRepo.updatePassword(_currentUser!.id, newHash);
    _currentUser = await _userRepo.getById(_currentUser!.id);
    _mustChangeAdminPassword = false;
    if (_currentUser != null) {
      await _saveSession(_currentUser!);
    }
    notifyListeners();
    return true;
  }
}
