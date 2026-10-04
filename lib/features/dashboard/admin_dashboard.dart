import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/features/authentication/domain/auth_service.dart';
import 'admin_dashboard_overview.dart';
import 'package:my_lucky_lotto_pred/features/synchronization/presentation/admin_sync_page.dart';
import 'package:my_lucky_lotto_pred/features/lotto_results/presentation/admin_results_management_page.dart';
import 'package:my_lucky_lotto_pred/features/users/presentation/admin_users_page.dart';
import 'package:my_lucky_lotto_pred/features/settings/presentation/admin_settings_page.dart';
import 'package:my_lucky_lotto_pred/features/migration/presentation/migration_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final pages = [
      AdminDashboardOverview(onNavigateTab: (idx) {
        if (idx == 1) setState(() => _selectedIndex = 1);
        if (idx == 2) setState(() => _selectedIndex = 1);
        if (idx == 3) setState(() => _selectedIndex = 2);
        if (idx == 4) setState(() => _selectedIndex = 3);
        if (idx == 5) setState(() => _selectedIndex = 1);
        if (idx == 6) setState(() => _selectedIndex = 4);
        if (idx == 7) setState(() => _selectedIndex = 5);
      }),
      const AdminSyncPage(),
      const AdminResultsManagementPage(),
      const AdminUsersPage(),
      const AdminSettingsPage(),
      const MigrationPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield, color: Color(0xFFFFB300)),
            const SizedBox(width: 10),
            const Text('LLIS Administrator Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              child: const Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text('Administrator: ${auth.currentUser?.username}')),
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
              if (val == 'logout') auth.logout();
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
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.admin_panel_settings, color: Color(0xFFFFB300)),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync), label: Text('Sync PCSO')),
                NavigationRailDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list), label: Text('Results')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                NavigationRailDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: Text('Legacy Import')),
              ],
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}
