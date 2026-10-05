import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/user.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool forceSync = true}) async {
    setState(() => _isLoading = true);
    final repo = context.read<UserRepository>();
    final users = await repo.getAllUsers(forceSync: forceSync);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registered User Directory',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage registered accounts, view roles, or deactivate accounts.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh user directory from database',
                    onPressed: () => _loadUsers(forceSync: true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_users.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No registered users found.', style: TextStyle(color: Colors.blueGrey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: u.isActive
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                              : Colors.red.withValues(alpha: 0.35),
                          width: u.isActive ? 1.0 : 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: u.isAdmin
                              ? const Color(0xFF4F46E5)
                              : (u.isActive ? Colors.blue.shade100 : Colors.red.shade100),
                          foregroundColor: u.isAdmin
                              ? Colors.white
                              : (u.isActive ? Colors.blue.shade900 : Colors.red.shade900),
                          child: Text(
                            u.username.isNotEmpty ? u.username.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              u.fullName.isNotEmpty ? u.fullName : u.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: u.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: u.isAdmin ? Colors.amber.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                u.role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: u.isAdmin ? Colors.brown.shade800 : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: u.isActive
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: u.isActive
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                u.isActive ? 'ACTIVE' : 'DEACTIVATED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: u.isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username: ${u.username}',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                              ),
                              if (u.email.isNotEmpty)
                                Text(
                                  'Email: ${u.email}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        trailing: u.isAdmin
                            ? Tooltip(
                                message: 'Root Admin accounts cannot be deactivated',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield_rounded, color: Colors.amber, size: 20),
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  u.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                                  color: u.isActive ? Colors.red : Colors.green,
                                  size: 24,
                                ),
                                tooltip: u.isActive ? 'Deactivate User (Block Access)' : 'Activate User (Grant Access)',
                                onPressed: () async {
                                  final repo = context.read<UserRepository>();
                                  final messenger = ScaffoldMessenger.of(context);
                                  final actionText = u.isActive ? 'deactivated' : 'activated';

                                  if (u.isActive) {
                                    await repo.deactivateUser(u.id, username: u.username);
                                  } else {
                                    await repo.activateUser(u.id, username: u.username);
                                  }

                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('User "${u.username}" has been $actionText successfully.'),
                                      backgroundColor: u.isActive ? Colors.red.shade700 : Colors.green.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );

                                  await _loadUsers(forceSync: true);
                                },
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
