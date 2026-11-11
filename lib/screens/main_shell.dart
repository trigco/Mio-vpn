import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../widgets/app_icons.dart';
import 'config_management_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

/// Root scaffold with the premium bottom navigation:
/// Home / Configs / Tools / Settings.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget navIcon(List<List<dynamic>> icon, bool selected) {
      return HugeIcon(
        icon: icon,
        size: 24,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onGoTab: _goTab),
          const ConfigManagementScreen(),
          const ToolsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTab,
        destinations: [
          NavigationDestination(
            icon: navIcon(AppIcons.home, _index == 0),
            label: 'Home',
          ),
          NavigationDestination(
            icon: navIcon(AppIcons.sliders, _index == 1),
            label: 'Configs',
          ),
          NavigationDestination(
            icon: navIcon(AppIcons.grid, _index == 2),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: navIcon(AppIcons.settings, _index == 3),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
