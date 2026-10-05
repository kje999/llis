import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:my_lucky_lotto_pred/core/constants/api_constants.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _backendUrlController = TextEditingController(text: ApiConstants.baseUrl);
  String? _message;
  bool _isError = false;
  String? _backendStatusMessage;
  bool _isBackendError = false;
  bool _isTestingBackend = false;

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
                'System & Administrator Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 4),
              const Text('Manage administrative security credentials, sync frequency, and preferences.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                        SizedBox(
                          width: isMobile ? double.infinity : null,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _handleChangePassword,
                            child: const Text('Update Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Backend Cloud Service & API Configuration Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_sync, color: Color(0xFF1E3A8A), size: 22),
                            SizedBox(width: 8),
                            Text('Backend Cloud Service Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Configure the remote 24/7 backend sync service URL (e.g. Render, Railway, or local port).',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        if (_backendStatusMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _isBackendError ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _isBackendError ? Colors.red.shade200 : Colors.green.shade200),
                            ),
                            child: Text(
                              _backendStatusMessage!,
                              style: TextStyle(color: _isBackendError ? Colors.red : Colors.green, fontSize: 12.5),
                            ),
                          ),
                        TextField(
                          controller: _backendUrlController,
                          decoration: InputDecoration(
                            labelText: 'Backend Service Base URL',
                            hintText: 'https://llis.onrender.com or http://localhost:8081',
                            border: const OutlineInputBorder(),
                            helperText: 'Active: ${ApiConstants.baseUrl}',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                foregroundColor: Colors.white,
                              ),
                              icon: _isTestingBackend
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.network_check, size: 18),
                              label: const Text('Test Connection'),
                              onPressed: _isTestingBackend ? null : _testBackendConnection,
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Save URL'),
                              onPressed: _saveBackendUrl,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset to Default'),
                              onPressed: _resetBackendUrl,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _testBackendConnection() async {
    final targetUrl = _backendUrlController.text.trim();
    if (targetUrl.isEmpty) {
      setState(() {
        _isBackendError = true;
        _backendStatusMessage = 'Please enter a valid backend URL.';
      });
      return;
    }

    setState(() {
      _isTestingBackend = true;
      _backendStatusMessage = null;
    });

    try {
      final clean = targetUrl.replaceAll(RegExp(r'/+$'), '');
      final res = await http.get(Uri.parse('$clean/api/health')).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isTestingBackend = false;
          if (res.statusCode == 200) {
            _isBackendError = false;
            _backendStatusMessage = '✓ Connected successfully! Service returned HTTP 200 OK.';
          } else {
            _isBackendError = true;
            _backendStatusMessage = 'Service reachable but returned HTTP ${res.statusCode}.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingBackend = false;
          _isBackendError = true;
          _backendStatusMessage = 'Connection failed: ${e.toString()}';
        });
      }
    }
  }

  void _saveBackendUrl() {
    final targetUrl = _backendUrlController.text.trim();
    ApiConstants.setCustomBaseUrl(targetUrl);
    setState(() {
      _isBackendError = false;
      _backendStatusMessage = '✓ Backend URL saved: ${ApiConstants.baseUrl}';
      _backendUrlController.text = ApiConstants.baseUrl;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Active backend URL set to: ${ApiConstants.baseUrl}'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  void _resetBackendUrl() {
    ApiConstants.setCustomBaseUrl(null);
    setState(() {
      _isBackendError = false;
      _backendStatusMessage = 'Reset to default: ${ApiConstants.baseUrl}';
      _backendUrlController.text = ApiConstants.baseUrl;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reset backend URL to default: ${ApiConstants.baseUrl}'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }
}
