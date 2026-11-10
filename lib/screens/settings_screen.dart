import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import 'connection_log_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, 'Appearance'),
              Card(
                child: Column(
                  children: [
                    _row(
                      context,
                      icon: AppIcons.paint,
                      color: const Color(0xFFA855F7),
                      title: 'App Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: state.themeOption.seed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(state.themeOption.label,
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 18, color: scheme.onSurfaceVariant),
                        ],
                      ),
                      onTap: () => _showThemePicker(context, state),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _section(context, 'Connection'),
              Card(
                child: Column(
                  children: [
                    _row(
                      context,
                      icon: AppIcons.share,
                      color: const Color(0xFF42A5F5),
                      title: 'Proxy Port',
                      trailing: _value(context, '${state.proxyPort}'),
                      onTap: () => _showPortDialog(context, state),
                    ),
                    const Divider(indent: 66),
                    _row(
                      context,
                      icon: AppIcons.key,
                      color: const Color(0xFFBA68C8),
                      title: 'Default Mode',
                      trailing: _value(context,
                          state.connectionMode == 'proxy' ? 'Proxy Mode' : 'VPN Mode'),
                      onTap: () => _showModePicker(context, state),
                    ),
                    const Divider(indent: 66),
                    _switchRow(
                      context,
                      icon: AppIcons.power,
                      color: const Color(0xFF7986CB),
                      title: 'Auto Connect',
                      subtitle: 'Connect on app start',
                      value: state.autoConnect,
                      onChanged: state.setAutoConnect,
                    ),
                    const Divider(indent: 66),
                    _switchRow(
                      context,
                      icon: AppIcons.activity,
                      color: const Color(0xFF66BB6A),
                      title: 'Keep Alive',
                      subtitle: 'Prevent connection drop',
                      value: state.keepAlive,
                      onChanged: state.setKeepAlive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _section(context, 'DNS Detection'),
              Card(
                child: _switchRow(
                  context,
                  icon: AppIcons.server,
                  color: const Color(0xFF26A69A),
                  title: 'Use Local DNS (Beta)',
                  subtitle: state.useAutoDns
                      ? (state.activeDns != null
                          ? 'Detected: ${state.activeDns!.address}'
                          : state.autoDnsError ?? 'Detecting...')
                      : 'Use system DNS from active network',
                  value: state.useAutoDns,
                  onChanged: state.setUseAutoDns,
                ),
              ),
              const SizedBox(height: 18),
              _section(context, 'Connection Log'),
              Card(
                child: Column(
                  children: [
                    _switchRow(
                      context,
                      icon: AppIcons.note,
                      color: const Color(0xFF42A5F5),
                      title: 'Show Connection Log',
                      subtitle: 'Debug & session logs',
                      value: state.showConnectionLog,
                      onChanged: state.setShowConnectionLog,
                    ),
                    const Divider(indent: 66),
                    _row(
                      context,
                      icon: AppIcons.file,
                      color: const Color(0xFFFFA726),
                      title: 'View Log',
                      trailing: _value(context, '${state.connectionLog.length} entries'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConnectionLogScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _section(context, 'About'),
              Card(
                child: _row(
                  context,
                  icon: AppIcons.shield,
                  color: scheme.primary,
                  title: 'DNS Pro',
                  trailing: _value(context, 'Version 2.2.0'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _value(BuildContext context, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color color,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: IconChip(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: IconChip(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _showThemePicker(BuildContext context, AppState state) {
    const icons = {
      AppThemeOption.light: AppIcons.sun,
      AppThemeOption.dark: AppIcons.moon,
      AppThemeOption.amoled: AppIcons.moon,
      AppThemeOption.purple: AppIcons.paint,
      AppThemeOption.blue: AppIcons.droplet,
      AppThemeOption.green: AppIcons.leaf,
    };
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('App Theme',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            for (final option in AppThemeOption.values)
              ListTile(
                leading: IconChip(icon: icons[option]!, color: option.seed),
                title: Text(option.label),
                trailing: state.themeOption == option
                    ? HugeIcon(
                        icon: AppIcons.tick,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  state.setThemeOption(option);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showModePicker(BuildContext context, AppState state) {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desktop always uses Proxy Mode')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Default Mode',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            for (final (mode, label, icon) in [
              ('vpn', 'VPN Mode', AppIcons.key),
              ('proxy', 'Proxy Mode', AppIcons.share),
            ])
              ListTile(
                leading: IconChip(
                    icon: icon, color: Theme.of(context).colorScheme.primary),
                title: Text(label),
                trailing: state.connectionMode == mode
                    ? HugeIcon(
                        icon: AppIcons.tick,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  state.setConnectionMode(mode);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showPortDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.proxyPort.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Local Proxy Port'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '1080',
                helperText: 'Port for local SOCKS5 proxy (1-65535)',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Change takes effect on next connection.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(controller.text.trim());
              if (port != null && port >= 1 && port <= 65535) {
                state.setProxyPort(port);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Proxy port set to $port')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid port (1-65535)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
