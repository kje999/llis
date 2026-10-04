import 'package:flutter/foundation.dart';
import '../../../core/security/password_hasher.dart';
import '../../../shared/models/user.dart';
import '../domain/user_repository.dart';

class AuthService extends ChangeNotifier {
  final UserRepository _userRepo;
  User? _currentUser;
  bool _mustChangeAdminPassword = false;

  AuthService(this._userRepo);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get mustChangeAdminPassword => _mustChangeAdminPassword;

  Future<bool> login(String username, String password) async {
    final user = await _userRepo.getByUsername(username.trim());
    if (user == null || !user.isActive) {
      return false;
    }

    final isValid = PasswordHasher.verify(password, user.passwordHash);
    if (!isValid) return false;

    _currentUser = user;

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
    notifyListeners();
    return true;
  }
}
