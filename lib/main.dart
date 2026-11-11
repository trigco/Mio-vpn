import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';
import 'models/dns_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final appState = AppState();
  await appState.init(storage);

  // Add default DNS server if none exists
  if (appState.dnsServers.isEmpty) {
    final defaultDns = DnsServer(
      name: 'Google DNS',
      address: '8.8.8.8',
    );
    await appState.addDnsServer(defaultDns);
    await appState.setActiveDns(defaultDns);
  }

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const DnsProApp(),
    ),
  );
}

class DnsProApp extends StatelessWidget {
  const DnsProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeOption = context.watch<AppState>().themeOption;
    return MaterialApp(
      title: 'DNS Pro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(themeOption),
      home: const MainShell(),
    );
  }
}
