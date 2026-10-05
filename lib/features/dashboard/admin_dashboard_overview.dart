import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_repository.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/user_repository.dart';

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
    final syncService = context.read<SynchronizationService>();
    var totalRes = await resultRepo.getTotalCount();
    if (totalRes == 0) {
      await syncService.loadCachedResultsFromBackend();
      totalRes = await resultRepo.getTotalCount();
    }
    final yearRes = await resultRepo.getCountThisYear();
    var totalPicks = await pickRepo.getTotalCount();
    if (totalPicks == 0) {
      await pickRepo.syncPicksFromBackend();
      totalPicks = await pickRepo.getTotalCount();
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth > 500 ? constraints.maxWidth - 200 : constraints.maxWidth),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator Management Dashboard',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Full management of PCSO synchronization, user accounts, and lottery results.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.sync),
                      label: const Text('SYNC LOTTO RESULTS', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => widget.onNavigateTab(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // KPI Metrics Grid
                GridView.count(
                  crossAxisCount: constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 480 ? 2 : 1),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth > 800 ? 1.5 : (constraints.maxWidth > 480 ? 1.4 : 2.6),
                  children: [
                    _buildKpiCard('Registered Users', '$_totalUsers', Icons.people, Colors.blue),
                    _buildKpiCard('Total PCSO Draws', '$_totalResults', Icons.list_alt, Colors.green),
                    _buildKpiCard('Draws This Year', '$_resultsThisYear', Icons.event, Colors.indigo),
                    _buildKpiCard('Saved Lucky Picks', '$_totalLuckyPicks', Icons.casino, Colors.purple),
                  ],
                ),
                const SizedBox(height: 20),
                // Sync Status Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_done, color: Colors.green, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PCSO Result Synchronization Status',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last Synchronized: $_lastSyncTime\nStatus: ✓ Up to date  |  Failures: $_syncFailures',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: isMobile ? double.infinity : null,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('View Sync Logs'),
                            onPressed: () => widget.onNavigateTab(2),
                          ),
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
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
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
