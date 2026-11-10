import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_icons.dart';
import 'config_management_screen.dart';
import 'connection_log_screen.dart';
import 'dns_management_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.12,
                children: [
                  _tile(
                    context,
                    icon: AppIcons.note,
                    color: const Color(0xFF42A5F5),
                    title: 'Connection Log',
                    subtitle: state.showConnectionLog
                        ? '${state.connectionLog.length} entries'
                        : 'Turned off',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConnectionLogScreen()),
                    ),
                  ),
                  _tile(
                    context,
                    icon: AppIcons.testTube,
                    color: const Color(0xFF66BB6A),
                    title: 'Test DNS',
                    subtitle: state.isTestingAll
                        ? 'Testing ${state.testingProgress}/${state.testingTotal}…'
                        : 'Find fastest server',
                    onTap: () async {
                      if (state.isTestingAll) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Testing all DNS servers…')),
                      );
                      await state.startTestingAllDnsServers();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Done: ${state.testingWorking} working, ${state.testingFailed} failed'),
                          ),
                        );
                      }
                    },
                  ),
                  _tile(
                    context,
                    icon: AppIcons.server,
                    color: const Color(0xFF26A69A),
                    title: 'DNS Servers',
                    subtitle: '${state.dnsServers.length} servers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DnsManagementScreen()),
                    ),
                  ),
                  _tile(
                    context,
                    icon: AppIcons.sliders,
                    color: const Color(0xFFBA68C8),
                    title: 'Configs',
                    subtitle: '${state.dnsttConfigs.length} configurations',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConfigManagementScreen()),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(icon: icon, color: color, boxSize: 44, size: 22),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
