import '../shared/models/user.dart';

abstract class UserRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getById(int id);
  Future<User?> getByUsername(String username);
  Future<int> insertUser(User user);
  Future<void> updateUser(User user);
  Future<void> updatePassword(int userId, String newHash);
  Future<void> deactivateUser(int userId);
  Future<void> deleteUser(int userId);
  Future<int> countAdminUsers();
}
