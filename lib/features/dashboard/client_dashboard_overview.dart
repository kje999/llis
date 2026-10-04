import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';

class ClientDashboardOverview extends StatefulWidget {
  final Function(int) onNavigateTab;

  const ClientDashboardOverview({super.key, required this.onNavigateTab});

  @override
  State<ClientDashboardOverview> createState() => _ClientDashboardOverviewState();
}

class _ClientDashboardOverviewState extends State<ClientDashboardOverview> {
  List<LottoResult> _latestResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    final resultRepo = context.read<LottoResultRepository>();
    final results = await resultRepo.getAll(limit: 5);
    if (mounted) {
      setState(() {
        _latestResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.fullName ?? 'Player'}!',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Philippine PCSO 6-Number Lotto Modern Information Dashboard',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Data Synchronized & Offline Ready', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LottoDisclaimerBanner(),
          const SizedBox(height: 16),
          // PCSO Draw Schedule Quick Reminder Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Color(0xFFFFB300), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Official PCSO Draw Schedule & Days (All Major 6-Number Games)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildGameScheduleChip('Ultra 6/58', 'Sun • Tue • Fri', '₱49.5M+'),
                    _buildGameScheduleChip('Grand 6/55', 'Mon • Wed • Sat', '₱29.7M+'),
                    _buildGameScheduleChip('Super 6/49', 'Sun • Tue • Thu', '₱15.8M+'),
                    _buildGameScheduleChip('Mega 6/45', 'Mon • Wed • Fri', '₱8.9M+'),
                    _buildGameScheduleChip('Lotto 6/42', 'Tue • Thu • Sat', '₱5.9M+'),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'All official PCSO 6-digit draws occur at 9:00 PM PHT. Minimum 3 matching numbers win official prizes.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.8 : 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickActionCard(
                    title: 'Lucky Pick Generator',
                    desc: 'Generate & speak random numbers',
                    icon: Icons.casino,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => widget.onNavigateTab(1),
                  ),
                  _buildQuickActionCard(
                    title: 'Statistical Suggestions',
                    desc: 'Ranked historical combinations',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFFF59E0B),
                    onTap: () => widget.onNavigateTab(4),
                  ),
                  _buildQuickActionCard(
                    title: '1-Year Analytics',
                    desc: 'Hot, cold, overdue numbers & pairs',
                    icon: Icons.bar_chart,
                    color: const Color(0xFF10B981),
                    onTap: () => widget.onNavigateTab(3),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Latest Official PCSO Draws', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              TextButton(onPressed: () => widget.onNavigateTab(2), child: const Text('View All Draws')),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _latestResults.length,
              itemBuilder: (context, index) {
                final r = _latestResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.lottoTypeName ?? 'PCSO Lotto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Draw Date: ${r.drawDate}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        Wrap(
                          spacing: 4,
                          children: r.numbers.map((n) => LottoBall(number: n, size: 32)).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScheduleChip(String title, String days, String minJackpot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(4)),
                child: Text(minJackpot, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(days, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
