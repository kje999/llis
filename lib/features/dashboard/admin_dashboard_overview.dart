import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/domain/auth_service.dart';
import '../../lotto_results/domain/lotto_result_repository.dart';
import '../../lucky_pick/domain/lucky_pick_repository.dart';
import '../../synchronization/domain/synchronization_repository.dart';
import '../../authentication/domain/user_repository.dart';

class AdminDashboardOverview extends StatefulWidget {
  final Function(int) onNavigateTab;

  const AdminDashboardOverview({super.key, required this.onNavigateTab});

  @override
  State<AdminDashboardOverview> createState() => _AdminDashboardOverviewState();
}

class _AdminDashboardOverviewState extends State<AdminDashboardOverview> {
  int _totalUsers = 0;
  int _totalResults = 0;
  int _resultsThisYear = 0;
  int _totalLuckyPicks = 0;
  int _syncFailures = 0;
  String _lastSyncTime = 'Checking...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final userRepo = context.read<UserRepository>();
    final resultRepo = context.read<LottoResultRepository>();
    final pickRepo = context.read<LuckyPickRepository>();
    final syncRepo = context.read<SynchronizationRepository>();

    final users = await userRepo.getAllUsers();
    final totalRes = await resultRepo.getTotalCount();
    final yearRes = await resultRepo.getCountThisYear();
    final totalPicks = await pickRepo.getTotalCount();
    final failures = await syncRepo.getFailureCount();
    final latestSync = await syncRepo.getLatestLog();

    if (mounted) {
      setState(() {
        _totalUsers = users.length;
        _totalResults = totalRes;
        _resultsThisYear = yearRes;
        _totalLuckyPicks = totalPicks;
        _syncFailures = failures;
        _lastSyncTime = latestSync != null
            ? latestSync.completedAt.toLocal().toString().substring(0, 16)
            : 'Up to date';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrator Management Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Full management of PCSO synchronization, user accounts, and lottery results.',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.sync),
                label: const Text('SYNC LOTTO RESULTS', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => widget.onNavigateTab(1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // KPI Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.5 : 1.3,
                  children: [
                    _buildKpiCard('Registered Users', '$_totalUsers', Icons.people, Colors.blue),
                    _buildKpiCard('Total PCSO Draws', '$_totalResults', Icons.list_alt, Colors.green),
                    _buildKpiCard('Draws This Year', '$_resultsThisYear', Icons.event, Colors.indigo),
                    _buildKpiCard('Saved Lucky Picks', '$_totalLuckyPicks', Icons.casino, Colors.purple),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // Sync Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_done, color: Colors.green, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PCSO Result Synchronization Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Last Synchronized: $_lastSyncTime  |  Status: ✓ Up to date  |  Failures: $_syncFailures', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('View Sync Logs'),
                      onPressed: () => widget.onNavigateTab(2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quick Admin Actions
            const Text('System Administration Modules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildModuleButton('Official Results Management', Icons.edit_calendar, () => widget.onNavigateTab(3)),
                _buildModuleButton('User Directory & Access', Icons.manage_accounts, () => widget.onNavigateTab(4)),
                _buildModuleButton('Audit Logs', Icons.security, () => widget.onNavigateTab(5)),
                _buildModuleButton('System Settings & Passwords', Icons.settings, () => widget.onNavigateTab(6)),
                _buildModuleButton('Legacy MySQL Import', Icons.upload_file, () => widget.onNavigateTab(7)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleButton(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
