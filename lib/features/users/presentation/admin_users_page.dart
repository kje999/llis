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

  Future<void> _loadUsers() async {
    final repo = context.read<UserRepository>();
    final users = await repo.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registered User Directory',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 4),
              const Text('Manage registered accounts, view roles, or deactivate accounts.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: u.isAdmin ? Colors.indigo : Colors.blue.shade100,
                          foregroundColor: u.isAdmin ? Colors.white : Colors.blue.shade900,
                          child: Text(u.username.isNotEmpty ? u.username.substring(0, 1).toUpperCase() : '?'),
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: u.isAdmin ? Colors.amber.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(u.role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: u.isAdmin ? Colors.brown.shade800 : Colors.black87)),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username: ${u.username} • Active: ${u.isActive ? "Yes" : "No"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text('Email: ${u.email}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        trailing: u.isAdmin
                            ? null
                            : IconButton(
                                icon: Icon(u.isActive ? Icons.block : Icons.check, color: u.isActive ? Colors.red : Colors.green),
                                tooltip: u.isActive ? 'Deactivate User' : 'Activate User',
                                onPressed: () async {
                                  final repo = context.read<UserRepository>();
                                  if (u.isActive) {
                                    await repo.deactivateUser(u.id);
                                  } else {
                                    await repo.updateUser(User(
                                      id: u.id,
                                      username: u.username,
                                      passwordHash: u.passwordHash,
                                      role: u.role,
                                      fullName: u.fullName,
                                      email: u.email,
                                      createdAt: u.createdAt,
                                      updatedAt: DateTime.now(),
                                      isActive: true,
                                    ));
                                  }
                                  _loadUsers();
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
