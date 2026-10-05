import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';
import 'package:my_lucky_lotto_pred/core/theme/theme_service.dart';
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

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      AdminDashboardOverview(onNavigateTab: (idx) {
        if (idx == 1) _onSelectTab(1);
        if (idx == 2) _onSelectTab(1);
        if (idx == 3) _onSelectTab(2);
        if (idx == 4) _onSelectTab(3);
        if (idx == 5) _onSelectTab(1);
        if (idx == 6) _onSelectTab(4);
        if (idx == 7) _onSelectTab(5);
      }),
      const AdminSyncPage(),
      const AdminResultsManagementPage(),
      const AdminUsersPage(),
      const AdminSettingsPage(),
      const MigrationPage(),
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
                  child: const Icon(Icons.shield, color: Color(0xFF0F172A), size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  isSmall ? 'LLIS Admin' : 'LLIS Admin Console',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                if (!isSmall) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.pcsoRed.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text('Administrator: ${auth.currentUser?.username}'),
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
              if (val == 'logout') auth.logout();
            },
          ),
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
                              child: const Icon(Icons.shield, color: Color(0xFF0F172A), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LLIS Admin Panel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Philippine PCSO Control Room',
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
                              const Icon(Icons.admin_panel_settings, color: Color(0xFFFFB300), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Root Administrator: ${auth.currentUser?.username}',
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
                        _buildDrawerTile(Icons.sync_rounded, 'Sync PCSO', 1),
                        _buildDrawerTile(Icons.view_list_rounded, 'Draw Results', 2),
                        _buildDrawerTile(Icons.people_alt_rounded, 'User Management', 3),
                        _buildDrawerTile(Icons.settings_rounded, 'System Settings', 4),
                        _buildDrawerTile(Icons.upload_file_rounded, 'Legacy Import', 5),
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
                child: const Icon(Icons.admin_panel_settings, color: Color(0xFF0F172A), size: 20),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync), label: Text('Sync PCSO')),
                NavigationRailDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list), label: Text('Results')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                NavigationRailDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: Text('Import')),
              ],
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex < 4 ? _selectedIndex : 0,
              onDestinationSelected: (idx) => _onSelectTab(idx),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              indicatorColor: AppTheme.pcsoBlue.withValues(alpha: 0.15),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.pcsoBlue), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync, color: AppTheme.pcsoBlue), label: 'Sync'),
                NavigationDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list, color: AppTheme.pcsoBlue), label: 'Results'),
                NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppTheme.pcsoBlue), label: 'Users'),
              ],
            ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.pcsoBlue.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppTheme.pcsoBlue : null),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.pcsoBlue : null,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _onSelectTab(index);
        },
      ),
    );
  }
}
