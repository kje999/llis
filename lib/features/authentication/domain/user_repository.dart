import 'package:my_lucky_lotto_pred/shared/models/user.dart';

abstract class UserRepository {
  Future<List<User>> getAllUsers({bool forceSync = false});
  Future<User?> getById(int id);
  Future<User?> getByUsername(String username, {bool forceSync = false});
  Future<int> insertUser(User user);
  Future<void> updateUser(User user);
  Future<void> updatePassword(int userId, String newHash);
  Future<void> deactivateUser(int userId, {String? username});
  Future<void> activateUser(int userId, {String? username});
  Future<void> deleteUser(int userId);
  Future<int> countAdminUsers();
  Future<void> syncUsersFromBackend();
}
