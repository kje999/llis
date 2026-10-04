import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'package:my_lucky_lotto_pred/features/notifications/domain/notification_repository.dart';
import 'client_dashboard_overview.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/presentation/lucky_pick_page.dart';
import 'package:my_lucky_lotto_pred/features/lucky_pick/presentation/my_picks_page.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/presentation/lotto_results_page.dart';
import 'package:my_lucky_lotto_pred/features/analytics/presentation/analytics_page.dart';
import 'package:my_lucky_lotto_pred/features/predictions/presentation/predictions_page.dart';
import 'package:my_lucky_lotto_pred/features/notifications/presentation/notifications_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final pages = [
      ClientDashboardOverview(onNavigateTab: (idx) => setState(() => _selectedIndex = idx)),
      const LuckyPickPage(),
      const LottoResultsPage(),
      const AnalyticsPage(),
      const PredictionsPage(),
      const MyPicksPage(),
      const NotificationsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.casino, color: Color(0xFFFFB300)),
            const SizedBox(width: 10),
            const Text(
              'LLIS Modern Lotto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('CLIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () {
                  setState(() => _selectedIndex = 6);
                  _loadUnreadNotifications();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) {
                setState(() => _selectedIndex = idx);
                _loadUnreadNotifications();
              },
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.stars, color: Color(0xFFFFB300)),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: Text('Lucky Pick')),
                NavigationRailDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: Text('PCSO Results')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
                NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('Suggestions')),
                NavigationRailDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: Text('My Picks')),
                NavigationRailDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: Text('Notifications')),
              ],
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.casino), label: 'Lucky Pick'),
                NavigationDestination(icon: Icon(Icons.list_alt), label: 'Results'),
                NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Picks'),
              ],
            ),
    );
  }
}
