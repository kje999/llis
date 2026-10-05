import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/core/theme/theme_service.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/notifications/domain/notification_repository.dart';
import 'client_dashboard_overview.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/presentation/lucky_pick_page.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/presentation/my_picks_page.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/presentation/lotto_results_page.dart';
import 'package:my_lucky_lotto_pred/features/analytics/presentation/analytics_page.dart';
import 'package:my_lucky_lotto_pred/features/predictions/presentation/predictions_page.dart';
import 'package:my_lucky_lotto_pred/features/notifications/presentation/notifications_page.dart';
import 'package:my_lucky_lotto_pred/shared/widgets/developer_info_dialog.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _selectedIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthService>().validateCurrentSession();
    });
  }

  Future<void> _loadUnreadNotifications() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;
    final repo = context.read<NotificationRepository>();
    final count = await repo.getUnreadCount(auth.currentUser!.id);
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
    _loadUnreadNotifications();
    context.read<AuthService>().validateCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      ClientDashboardOverview(onNavigateTab: (idx) => _onSelectTab(idx)),
      const LuckyPickPage(),
      const LottoResultsPage(),
      const AnalyticsPage(),
      const PredictionsPage(),
      const MyPicksPage(),
      const NotificationsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.pcsoHeroGradient,
          ),
        ),
        title: Builder(
          builder: (context) {
            final isSmall = MediaQuery.of(context).size.width < 500;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.pcsoGoldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.casino, color: Color(0xFF0F172A), size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  isSmall ? 'LLIS Lotto' : 'LLIS Modern Lotto',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                if (!isSmall) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'CLIENT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFCD116)),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return IconButton(
                tooltip: themeService.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                  color: themeService.isDarkMode ? const Color(0xFFFFB300) : Colors.white,
                ),
                onPressed: () => themeService.toggleTheme(),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: () => _onSelectTab(6),
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFCE1126), shape: BoxShape.circle),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text('Signed in as ${auth.currentUser?.username}'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'logout') {
                auth.logout();
              }
            },
          ),
          const DeveloperInfoButton(compact: true),
          const SizedBox(width: 6),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.pcsoHeroGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                gradient: AppTheme.pcsoGoldGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.casino, color: Color(0xFF0F172A), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LLIS PCSO Hub',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Philippine Charity Sweepstakes',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Color(0xFFFFB300), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.currentUser?.fullName ?? auth.currentUser?.username ?? 'Player',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildDrawerTile(Icons.dashboard_rounded, 'Dashboard', 0),
                        _buildDrawerTile(Icons.casino_rounded, 'Lucky Pick Generator', 1),
                        _buildDrawerTile(Icons.format_list_numbered_rounded, 'PCSO Draw Results', 2),
                        _buildDrawerTile(Icons.analytics_rounded, 'Historical Analytics', 3),
                        _buildDrawerTile(Icons.auto_awesome_rounded, 'AI Suggestions', 4),
                        _buildDrawerTile(Icons.bookmark_rounded, 'My Saved Picks', 5),
                        _buildDrawerTile(Icons.notifications_rounded, 'Notifications', 6, badgeCount: _unreadCount),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      auth.logout();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => _onSelectTab(idx),
              labelType: NavigationRailLabelType.all,
              leading: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: AppTheme.pcsoGoldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: Color(0xFF0F172A), size: 20),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: Text('Lucky Pick')),
                NavigationRailDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: Text('Results')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
                NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('Suggestions')),
                NavigationRailDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: Text('My Picks')),
                NavigationRailDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: Text('Alerts')),
              ],
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
                onDestinationSelected: (idx) => _onSelectTab(idx),
                backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                indicatorColor: AppTheme.pcsoBlue.withValues(alpha: 0.15),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.pcsoBlue), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino, color: AppTheme.pcsoBlue), label: 'Pick'),
                  NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt, color: AppTheme.pcsoBlue), label: 'Results'),
                  NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics, color: AppTheme.pcsoBlue), label: 'Analytics'),
                  NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.pcsoBlue), label: 'Suggest'),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int index, {int badgeCount = 0}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.pcsoBlue.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.pcsoBlue : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.pcsoBlue : null,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(color: Color(0xFFCE1126), shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          _onSelectTab(index);
        },
      ),
    );
  }
}
