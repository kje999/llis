import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/domain/lotto_result_repository.dart';
import 'package:my_lucky_lotto_pred/shared/models/lotto_result.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_ball.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/lotto_disclaimer_banner.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/domain/synchronization_service.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/domain/lucky_pick_repository.dart';

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
    final syncService = context.read<SynchronizationService>();
    final auth = context.read<AuthService>();
    final pickRepo = context.read<LuckyPickRepository>();

    if (auth.currentUser != null) {
      await pickRepo.syncPicksFromBackend(
        userId: auth.currentUser!.id,
        username: auth.currentUser!.username,
      );
    }

    var results = await resultRepo.getAll(limit: 6);
    if (results.isEmpty) {
      await syncService.loadCachedResultsFromBackend();
      results = await resultRepo.getAll(limit: 6);
    }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PCSO Hero Interactive Welcome Card
          _buildHeroBanner(user?.fullName ?? user?.username ?? 'Player', isDark),
          const SizedBox(height: 16),

          // 2. Official Disclaimer
          const LottoDisclaimerBanner(),
          const SizedBox(height: 16),

          // 3. Official PCSO Draw Schedule & Days Tracker
          _buildDrawScheduleSection(isDark),
          const SizedBox(height: 20),

          // 4. Quick Actions Hub (Entertaining Cards with responsive grid)
          _buildQuickActionsHub(isDark),
          const SizedBox(height: 24),

          // 5. Recent Official Draws Stream
          _buildRecentDrawsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(String userName, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.pcsoHeroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pcsoBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative glowing background circles (lotto balls aesthetic)
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.pcsoGold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.pcsoRed.withValues(alpha: 0.18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // PCSO Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.pcsoGoldGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.pcsoGold.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 14, color: Color(0xFF0F172A)),
                          SizedBox(width: 4),
                          Text(
                            'PCSO PHILIPPINES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sync Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt, size: 13, color: Color(0xFF34D399)),
                          SizedBox(width: 5),
                          Text(
                            'Central Database Synced',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Greeting & Title
                Text(
                  'Mabuhay, $userName! 🇵🇭',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your next-generation Philippine Lotto statistical analysis, lucky picks & jackpot tracker.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Fast Action Buttons in Hero
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pcsoGold,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => widget.onNavigateTab(1),
                      icon: const Icon(Icons.casino, size: 18),
                      label: const Text(
                        'Generate Lucky Pick',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => widget.onNavigateTab(4),
                      icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.pcsoGold),
                      label: const Text(
                        'View Suggestions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawScheduleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.pcsoGoldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_filled, color: Color(0xFF0F172A), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PCSO Official 9:00 PM Draw Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Daily live draw schedules for all 6-number lotto categories',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildGameScheduleChip('Ultra 6/58', 'Sun • Tue • Fri', '₱49.5M+', AppTheme.ultraColor, isDark),
              _buildGameScheduleChip('Grand 6/55', 'Mon • Wed • Sat', '₱29.7M+', AppTheme.grandColor, isDark),
              _buildGameScheduleChip('Super 6/49', 'Sun • Tue • Thu', '₱15.8M+', AppTheme.superColor, isDark),
              _buildGameScheduleChip('Mega 6/45', 'Mon • Wed • Fri', '₱8.9M+', AppTheme.megaColor, isDark),
              _buildGameScheduleChip('Lotto 6/42', 'Tue • Thu • Sat', '₱5.9M+', AppTheme.lottoColor, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameScheduleChip(
    String title,
    String days,
    String minJackpot,
    Color accentColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  gradient: AppTheme.pcsoGoldGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  minJackpot,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            days,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.blueGrey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHub(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interactive Features',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (width > 850) {
              crossAxisCount = 4;
            } else if (width > 480) {
              crossAxisCount = 2;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildActionCard(
                  title: 'Lucky Pick',
                  subtitle: 'RNG Generator & Voice Speech',
                  icon: Icons.casino_rounded,
                  gradient: AppTheme.pcsoBlueGradient,
                  onTap: () => widget.onNavigateTab(1),
                  badge: 'Popular',
                  isDark: isDark,
                ),
                _buildActionCard(
                  title: 'Manual Playslip',
                  subtitle: 'Interactive 3D Circle Shading',
                  icon: Icons.touch_app_rounded,
                  gradient: AppTheme.pcsoRedGradient,
                  onTap: () => widget.onNavigateTab(1),
                  badge: 'Interactive',
                  isDark: isDark,
                ),
                _buildActionCard(
                  title: 'Suggestions',
                  subtitle: 'Ranked historical combinations',
                  icon: Icons.auto_awesome,
                  gradient: AppTheme.pcsoGoldGradient,
                  textColor: const Color(0xFF0F172A),
                  onTap: () => widget.onNavigateTab(4),
                  badge: 'AI Driven',
                  isDark: isDark,
                ),
                _buildActionCard(
                  title: 'Analytics',
                  subtitle: 'Hot, cold & overdue number pairs',
                  icon: Icons.insights_rounded,
                  gradient: AppTheme.pcsoGreenGradient,
                  onTap: () => widget.onNavigateTab(3),
                  badge: '1-Year Stats',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required String badge,
    required bool isDark,
    Color textColor = Colors.white,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.blueGrey.shade200,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDrawsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.pcsoBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Latest Official PCSO Draws',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => widget.onNavigateTab(2),
              icon: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              label: const Icon(Icons.arrow_forward, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_latestResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('No draw results found. Tap "Sync PCSO" to fetch latest official data.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _latestResults.length,
            itemBuilder: (context, index) {
              final r = _latestResults[index];
              final formattedJackpot = r.jackpotPrize > 0
                  ? NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2).format(r.jackpotPrize)
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      final isSmall = boxConstraints.maxWidth < 450;
                      if (isSmall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.lottoTypeName ?? 'PCSO Lotto',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (formattedJackpot != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pcsoGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.pcsoGold.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      formattedJackpot,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Draw Date: ${r.drawDate}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: r.numbers.map((n) => LottoBall(number: n, size: 30)).toList(),
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      r.lottoTypeName ?? 'PCSO Lotto',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (formattedJackpot != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.pcsoGold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.pcsoGold.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          formattedJackpot,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Draw Date: ${r.drawDate}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: r.numbers.map((n) => LottoBall(number: n, size: 32)).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
