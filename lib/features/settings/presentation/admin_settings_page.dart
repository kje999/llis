import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/domain/auth_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System & Administrator Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text('Manage administrative security credentials, sync frequency, and preferences.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Change Administrator Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Regularly update your credentials to safeguard the system.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (_message != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isError ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Text(_message!, style: TextStyle(color: _isError ? Colors.red : Colors.green, fontSize: 13)),
                      ),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      onPressed: _handleChangePassword,
                      child: const Text('Update Password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final cur = _currentPasswordController.text;
    final neu = _newPasswordController.text;
    final con = _confirmPasswordController.text;

    if (cur.isEmpty || neu.isEmpty || con.isEmpty) {
      setState(() {
        _isError = true;
        _message = 'Please fill out all password fields.';
      });
      return;
    }

    if (neu != con) {
      setState(() {
        _isError = true;
        _message = 'New passwords do not match.';
      });
      return;
    }

    if (neu.length < 5) {
      setState(() {
        _isError = true;
        _message = 'New password must be at least 5 characters.';
      });
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.changePassword(oldPassword: cur, newPassword: neu);

    if (mounted) {
      setState(() {
        if (success) {
          _isError = false;
          _message = 'Password successfully updated!';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _isError = true;
          _message = 'Current password is incorrect.';
        }
      });
    }
  }
}
