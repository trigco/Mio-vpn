import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_icons.dart';

class ConnectionLogScreen extends StatelessWidget {
  const ConnectionLogScreen({super.key});

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(icon: AppIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Connection Log'),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: AppIcons.delete),
            tooltip: 'Clear log',
            onPressed: () =>
                context.read<AppState>().clearConnectionLog(),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.showConnectionLog) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Connection Log is turned off.\nEnable it in Settings.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final entries = state.connectionLog.reversed.toList();
          if (entries.isEmpty) {
            return const Center(child: Text('No log entries yet'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _fmt(e.time),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(e.message,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
