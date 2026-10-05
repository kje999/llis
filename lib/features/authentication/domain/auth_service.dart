import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_lucky_lotto_pred/core/constants/api_constants.dart';
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

  Timer? _sessionValidationTimer;
  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;

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
          if (!user.isAdmin) {
            startSessionGuard();
            validateCurrentSession();
          }
          notifyListeners();

          // Sync into database in background without blocking UI
          _ensureUserInDatabase(user);
          return;
        } else {
          _lastAuthError = 'ACCOUNT_DEACTIVATED';
          await _clearSession();
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

          if (!user.isAdmin) {
            startSessionGuard();
            validateCurrentSession();
          }

          _ensureUserInDatabase(user);
        } else if (user != null && !user.isActive) {
          _lastAuthError = 'ACCOUNT_DEACTIVATED';
          await _clearSession();
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

  /// Real-time session guard that validates whether the current user is still active in the central database.
  void startSessionGuard() {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      validateCurrentSession();
    });
  }

  void stopSessionGuard() {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = null;
  }

  /// Checks central backend / local database for user deactivation. If deactivated, forces immediate logout.
  Future<bool> validateCurrentSession() async {
    if (_currentUser == null) return false;
    if (_currentUser!.isAdmin) return true;

    try {
      final url = '${ApiConstants.baseUrl}/api/users';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List) {
          final targetUname = _currentUser!.username.toLowerCase().trim();
          for (final u in list) {
            if (u is Map && (u['username']?.toString().toLowerCase().trim() == targetUname)) {
              final rawActive = u['is_active'];
              final isActive = rawActive == 1 || rawActive == true || rawActive == '1';
              if (!isActive) {
                // User was deactivated by administrator!
                _lastAuthError = 'ACCOUNT_DEACTIVATED';
                await logout();
                return false;
              }
            }
          }
        }
      }
    } catch (_) {
      try {
        final local = await _userRepo.getByUsername(_currentUser!.username);
        if (local != null && !local.isActive) {
          _lastAuthError = 'ACCOUNT_DEACTIVATED';
          await logout();
          return false;
        }
      } catch (_) {}
    }
    return true;
  }

  Future<bool> login(String username, String password) async {
    _lastAuthError = null;

    // 1. Force sync latest user status from backend so any deactivations/updates are immediate
    try {
      await _userRepo.syncUsersFromBackend();
    } catch (_) {}

    final user = await _userRepo.getByUsername(username.trim());
    if (user == null) {
      _lastAuthError = 'USER_NOT_FOUND';
      return false;
    }

    if (!user.isActive) {
      _lastAuthError = 'ACCOUNT_DEACTIVATED';
      return false;
    }

    final isValid = PasswordHasher.verify(password, user.passwordHash);
    if (!isValid) {
      _lastAuthError = 'INVALID_PASSWORD';
      return false;
    }

    _currentUser = user;
    await _saveSession(user);

    // Check if it's default ADMIN with default password
    if (user.username.toUpperCase() == 'ADMIN' &&
        PasswordHasher.verify('ADMIN', user.passwordHash)) {
      _mustChangeAdminPassword = true;
    } else {
      _mustChangeAdminPassword = false;
    }

    // Start background session validation guard for non-admin users
    if (!user.isAdmin) {
      startSessionGuard();
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    stopSessionGuard();
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

  @override
  void dispose() {
    stopSessionGuard();
    super.dispose();
  }
}
