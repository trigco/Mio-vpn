import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_state.dart';
import '../models/dnstt_config.dart';
import '../services/config_import_export_service.dart';

class ConfigManagementScreen extends StatefulWidget {
  const ConfigManagementScreen({super.key});

  @override
  State<ConfigManagementScreen> createState() => _ConfigManagementScreenState();
}

enum _ConfigFilter { all, socks, ssh, slipstream }

class _ConfigManagementScreenState extends State<ConfigManagementScreen> {
  _ConfigFilter _filter = _ConfigFilter.all;

  bool _matches(DnsttConfig c) => switch (_filter) {
        _ConfigFilter.all => true,
        _ConfigFilter.socks => c.tunnelType == TunnelType.socks5,
        _ConfigFilter.ssh => c.tunnelType == TunnelType.ssh,
        _ConfigFilter.slipstream => c.isSlipstream,
      };

  Widget _buildFilterChips(AppState state) {
    Widget chip(_ConfigFilter f, String label) {
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == f,
          onSelected: (_) => setState(() => _filter = f),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          chip(_ConfigFilter.all, 'All (${state.dnsttConfigs.length})'),
          chip(_ConfigFilter.socks, 'Socks'),
          chip(_ConfigFilter.ssh, 'SSH'),
          chip(_ConfigFilter.slipstream, 'Slipstream'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import_url') {
                _showImportFromUrlDialog(context);
              } else if (value == 'import_clipboard') {
                _importFromClipboard(context);
              } else if (value == 'import_file') {
                _importFromFile(context);
              } else if (value == 'export') {
                _exportConfigs(context);
              } else if (value == 'import_dnsttxyz') {
                _importFromDnsttXyz(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_url',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download),
                    SizedBox(width: 8),
                    Text('Import from URL'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_clipboard',
                child: Row(
                  children: [
                    Icon(Icons.content_paste),
                    SizedBox(width: 8),
                    Text('Import from Clipboard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_file',
                child: Row(
                  children: [
                    Icon(Icons.file_open),
                    SizedBox(width: 8),
                    Text('Import from File'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_dnsttxyz',
                child: Row(
                  children: [
                    Icon(Icons.public),
                    SizedBox(width: 8),
                    Text('Import Online Server List'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Export Configs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddConfigDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Config'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.dnsttConfigs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Configs',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a config with public key and tunnel domain',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddConfigDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Config'),
                  ),
                ],
              ),
            );
          }

          final filtered = state.dnsttConfigs.where(_matches).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 1 + (filtered.isEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) return _buildFilterChips(state);
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('No configs match this filter')),
                );
              }
              final config = filtered[index - 1];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => state.setActiveConfig(config),
                  borderRadius: BorderRadius.circular(26),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: config.id,
                              groupValue: state.activeConfig?.id,
                              onChanged: (_) => state.setActiveConfig(config),
                              activeColor: Colors.green,
                            ),
                            Expanded(
                              child: Text(
                                config.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditConfigDialog(context, config);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, config);
                                }
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Domain', config.tunnelDomain),
                              const SizedBox(height: 8),
                              // Show public key
                              if (config.publicKey.isNotEmpty) ...[
                                _buildDetailRow(
                                  'Public Key',
                                  '${config.publicKey.substring(0, 16.clamp(0, config.publicKey.length))}...',
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Type',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: config.tunnelType == TunnelType.ssh
                                          ? Colors.purple[100]
                                          : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      config.tunnelType == TunnelType.ssh ? 'SSH' : 'Socks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: config.tunnelType == TunnelType.ssh
                                            ? Colors.purple[700]
                                            : Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: config.isSlipstream
                                          ? Colors.orange[100]
                                          : Colors.teal[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      config.isSlipstream ? 'Slipstream' : 'DNSTT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: config.isSlipstream
                                            ? Colors.orange[700]
                                            : Colors.teal[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  void _showAddConfigDialog(BuildContext context) {
    _showConfigDialog(context, null);
  }

  void _showEditConfigDialog(BuildContext context, DnsttConfig config) {
    _showConfigDialog(context, config);
  }

  void _showConfigDialog(BuildContext context, DnsttConfig? existingConfig) {
    showDialog(
      context: context,
      builder: (context) => _ConfigDialog(existingConfig: existingConfig),
    );
  }

  void _confirmDelete(BuildContext context, DnsttConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Config?'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().removeDnsttConfig(config.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Import/Export methods

  void _showImportFromUrlDialog(BuildContext context) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import from URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a URL pointing to a JSON file with DNSTT configs:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Config URL',
                hintText: 'https://example.com/configs.json',
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a URL')),
                );
                return;
              }

              Navigator.pop(dialogContext);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Importing configs...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final configs = await ConfigImportExportService.importConfigsFromUrl(url);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog

                  if (configs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No valid configs found in URL')),
                    );
                    return;
                  }

                  final state = context.read<AppState>();
                  final result = await state.importDnsttConfigs(configs);

                  if (context.mounted) {
                    String message;
                    if (result.added > 0 && result.updated > 0) {
                      message = 'Added ${result.added} new configs, updated ${result.updated}';
                    } else if (result.added > 0) {
                      message = 'Imported ${result.added} new configs';
                    } else if (result.updated > 0) {
                      message = 'Updated ${result.updated} existing configs';
                    } else {
                      message = 'All configs already exist';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message), backgroundColor: Colors.green),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim();

      if (text == null || text.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }

      final configs = ConfigImportExportService.importConfigsFromJson(text);

      if (configs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid configs found in clipboard'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final state = context.read<AppState>();
      final result = await state.importDnsttConfigs(configs);

      if (context.mounted) {
        String message;
        if (result.added > 0 && result.updated > 0) {
          message = 'Added ${result.added} new configs, updated ${result.updated}';
        } else if (result.added > 0) {
          message = 'Imported ${result.added} new configs';
        } else if (result.updated > 0) {
          message = 'Updated ${result.updated} existing configs';
        } else {
          message = 'All configs already exist';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportConfigs(BuildContext context) async {
    final state = context.read<AppState>();

    if (state.dnsttConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No configs to export')),
      );
      return;
    }

    final jsonString = ConfigImportExportService.exportConfigsToJson(state.dnsttConfigs);

    // On desktop, directly open native save dialog
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _saveJsonFile(context, jsonString, 'dnstt_configs.json');
      return;
    }

    // On mobile, show bottom sheet with Share and Save options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Export ${state.dnsttConfigs.length} Configs',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                subtitle: const Text('Send via apps, AirDrop, etc.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareJsonFile(context, jsonString, 'dnstt_configs.json', 'DNSTT Configs');
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save to File'),
                subtitle: const Text('Save JSON file to device'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveJsonFile(context, jsonString, 'dnstt_configs.json');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareJsonFile(BuildContext context, String jsonString, String fileName, String subject) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: subject,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveJsonFile(BuildContext context, String jsonString, String fileName) async {
    try {
      final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
      final bytes = utf8.encode(jsonString);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $fileName',
        fileName: fileName,
        type: isDesktop ? FileType.any : FileType.custom,
        allowedExtensions: isDesktop ? null : ['json'],
        bytes: isDesktop ? null : Uint8List.fromList(bytes),
      );

      if (result != null) {
        if (isDesktop) {
          await File(result).writeAsString(jsonString);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to file'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _importFromDnsttXyz(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching online server list...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await ConfigImportExportService.fetchDnsttXyzServers();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result.configs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No configs found in online list')),
          );
          return;
        }

        final state = context.read<AppState>();

        // Import configs
        final configResult = await state.importDnsttConfigs(result.configs);

        // Import DNS servers if any
        if (result.dnsServers.isNotEmpty) {
          await state.importDnsServers(result.dnsServers);
        }

        if (context.mounted) {
          String message = 'Imported ${configResult.added} configs';
          if (result.dnsServers.isNotEmpty) {
            message += ' and ${result.dnsServers.length} DNS servers';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch online list: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      String jsonString;

      if (file.bytes != null) {
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file');
      }

      final configs = ConfigImportExportService.importConfigsFromJson(jsonString);

      if (configs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid configs found in file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final state = context.read<AppState>();
      final importResult = await state.importDnsttConfigs(configs);

      if (context.mounted) {
        String message;
        if (importResult.added > 0 && importResult.updated > 0) {
          message = 'Added ${importResult.added} new configs, updated ${importResult.updated}';
        } else if (importResult.added > 0) {
          message = 'Imported ${importResult.added} new configs';
        } else if (importResult.updated > 0) {
          message = 'Updated ${importResult.updated} existing configs';
        } else {
          message = 'All configs already exist';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: importResult.added > 0 ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

/// Stateful dialog for adding/editing DNSTT configs with SSH tunnel support
class _ConfigDialog extends StatefulWidget {
  final DnsttConfig? existingConfig;

  const _ConfigDialog({this.existingConfig});

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late TextEditingController nameController;
  late TextEditingController publicKeyController;
  late TextEditingController domainController;
  late TextEditingController sshUsernameController;
  late TextEditingController sshPasswordController;
  late TextEditingController sshPortController;
  late TextEditingController socksUsernameController;
  late TextEditingController socksPasswordController;
  late TextEditingController keepAliveController;

  late TunnelType selectedTunnelType;
  late TransportType selectedTransportType;
  late String selectedCongestionControl;
  late bool gsoEnabled;
  bool showPassword = false;
  bool showSocksPassword = false;

  bool get _isSlipstream => selectedTransportType == TransportType.slipstream;
  bool get _isSsh => selectedTunnelType == TunnelType.ssh;

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;
    nameController = TextEditingController(text: c?.name ?? '');
    publicKeyController = TextEditingController(text: c?.publicKey ?? '');
    domainController = TextEditingController(text: c?.tunnelDomain ?? '');
    sshUsernameController = TextEditingController(text: c?.sshUsername ?? '');
    sshPasswordController = TextEditingController(text: c?.sshPassword ?? '');
    sshPortController =
        TextEditingController(text: c?.sshPort?.toString() ?? '');
    socksUsernameController =
        TextEditingController(text: c?.socksUsername ?? '');
    socksPasswordController =
        TextEditingController(text: c?.socksPassword ?? '');
    keepAliveController =
        TextEditingController(text: (c?.keepAliveInterval ?? 400).toString());
    selectedTunnelType = c?.tunnelType ?? TunnelType.socks5;
    selectedTransportType = c?.transportType ?? TransportType.dnstt;
    selectedCongestionControl = c?.congestionControl ?? 'dcubic';
    gsoEnabled = c?.gsoEnabled ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    publicKeyController.dispose();
    domainController.dispose();
    sshUsernameController.dispose();
    sshPasswordController.dispose();
    sshPortController.dispose();
    socksUsernameController.dispose();
    socksPasswordController.dispose();
    keepAliveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.existingConfig == null ? 'Add Config' : 'Edit Config'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Config Name',
                hintText: 'e.g., My Server',
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Protocol'),
            _buildSegmented<TransportType>(
              values: TransportType.values,
              selected: selectedTransportType,
              onChanged: (v) => setState(() => selectedTransportType = v),
              labelFor: (v) =>
                  v == TransportType.slipstream ? 'Slipstream' : 'DNSTT',
              colorFor: (v) => v == TransportType.slipstream
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF26A69A),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: domainController,
              decoration: const InputDecoration(
                labelText: 'Tunnel Domain',
                hintText: 'e.g., t.example.com',
              ),
              autocorrect: false,
            ),
            if (!_isSlipstream) ...[
              const SizedBox(height: 16),
              TextField(
                controller: publicKeyController,
                decoration: const InputDecoration(
                  labelText: 'Public Key (64 hex chars)',
                  hintText: 'Paste your public key here',
                ),
                maxLines: 2,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
            if (_isSlipstream) ...[
              const SizedBox(height: 20),
              _sectionLabel('Slipstream Settings', bold: true),
              DropdownButtonFormField<String>(
                initialValue: selectedCongestionControl,
                decoration: const InputDecoration(
                  labelText: 'Congestion Control',
                ),
                dropdownColor: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                items: const [
                  DropdownMenuItem(
                      value: 'dcubic', child: Text('DCubic (default)')),
                  DropdownMenuItem(value: 'bbr', child: Text('BBR')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCongestionControl = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keepAliveController,
                decoration: const InputDecoration(
                  labelText: 'Keep Alive (ms)',
                  helperText: 'Default: 400ms',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('GSO (Generic Segmentation Offload)'),
                subtitle: const Text('May improve throughput'),
                value: gsoEnabled,
                onChanged: (value) => setState(() => gsoEnabled = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 16),
            _sectionLabel('Tunnel Type'),
            _buildSegmented<TunnelType>(
              values: TunnelType.values,
              selected: selectedTunnelType,
              onChanged: (v) => setState(() => selectedTunnelType = v),
              labelFor: (v) => v == TunnelType.ssh ? 'SSH' : 'Socks',
              colorFor: (v) => v == TunnelType.ssh
                  ? const Color(0xFFBA68C8)
                  : const Color(0xFF42A5F5),
            ),
            if (_isSsh) ...[
              const SizedBox(height: 20),
              _sectionLabel('SSH Settings', bold: true),
              TextField(
                controller: sshUsernameController,
                decoration: const InputDecoration(
                  labelText: 'SSH Username',
                  hintText: 'e.g., root',
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: sshPasswordController,
                      decoration: InputDecoration(
                        labelText: 'SSH Password',
                        hintText: 'Your SSH password',
                        suffixIcon: IconButton(
                          icon: Icon(showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                        ),
                      ),
                      obscureText: !showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: sshPortController,
                      decoration: const InputDecoration(
                        labelText: 'SSH Port',
                        hintText: '22',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            if (!_isSsh) ...[
              const SizedBox(height: 20),
              _sectionLabel('SOCKS Authentication (optional)', bold: true),
              TextField(
                controller: socksUsernameController,
                decoration: const InputDecoration(
                  labelText: 'SOCKS Username',
                  hintText: 'Leave empty if not required',
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: socksPasswordController,
                decoration: InputDecoration(
                  labelText: 'SOCKS Password',
                  hintText: 'Leave empty if not required',
                  suffixIcon: IconButton(
                    icon: Icon(showSocksPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => showSocksPassword = !showSocksPassword),
                  ),
                ),
                obscureText: !showSocksPassword,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveConfig,
          child: Text(widget.existingConfig == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bold ? 12 : 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontSize: bold ? 15 : 13.5,
        ),
      ),
    );
  }

  /// Segmented pill selector with an unambiguous selected state in every
  /// theme: the selected segment is filled with its accent color and dark
  /// text; unselected segments sit on the raised surface color.
  Widget _buildSegmented<T>({
    required List<T> values,
    required T selected,
    required ValueChanged<T> onChanged,
    required String Function(T) labelFor,
    required Color Function(T) colorFor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: v == selected ? colorFor(v) : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    labelFor(v),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: v == selected
                          ? Colors.white
                          : scheme.onSurfaceVariant,
                      fontWeight:
                          v == selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _saveConfig() {
    final name = nameController.text.trim();
    final publicKey = publicKeyController.text.trim();
    final domain = domainController.text.trim();

    if (name.isEmpty || domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name and domain')),
      );
      return;
    }

    if (!_isSlipstream) {
      if (publicKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Public key is required for DNSTT')),
        );
        return;
      }
      if (publicKey.length != 64) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Public key must be 64 hex characters')),
        );
        return;
      }
    }

    int? sshPort;
    if (_isSsh) {
      final sshUsername = sshUsernameController.text.trim();
      final sshPassword = sshPasswordController.text;

      if (sshUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter SSH username')),
        );
        return;
      }
      if (sshPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter SSH password')),
        );
        return;
      }
      final portText = sshPortController.text.trim();
      if (portText.isNotEmpty) {
        sshPort = int.tryParse(portText);
        if (sshPort == null || sshPort < 1 || sshPort > 65535) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SSH port must be between 1 and 65535')),
          );
          return;
        }
      }
    }

    final socksUsername =
        !_isSsh && socksUsernameController.text.trim().isNotEmpty
            ? socksUsernameController.text.trim()
            : null;
    final socksPassword = !_isSsh && socksPasswordController.text.isNotEmpty
        ? socksPasswordController.text
        : null;

    final keepAlive = int.tryParse(keepAliveController.text.trim());
    final state = context.read<AppState>();

    if (widget.existingConfig == null) {
      state.addDnsttConfig(DnsttConfig(
        name: name,
        publicKey: !_isSlipstream ? publicKey : '',
        tunnelDomain: domain,
        tunnelType: selectedTunnelType,
        transportType: selectedTransportType,
        sshUsername: _isSsh ? sshUsernameController.text.trim() : null,
        sshPassword: _isSsh ? sshPasswordController.text : null,
        sshPort: _isSsh ? sshPort : null,
        socksUsername: socksUsername,
        socksPassword: socksPassword,
        congestionControl: _isSlipstream ? selectedCongestionControl : null,
        keepAliveInterval:
            _isSlipstream ? (keepAlive != null && keepAlive > 0 ? keepAlive : 400) : null,
        gsoEnabled: _isSlipstream ? gsoEnabled : null,
      ));
    } else {
      final c = widget.existingConfig!;
      c.name = name;
      c.publicKey = !_isSlipstream ? publicKey : '';
      c.tunnelDomain = domain;
      c.tunnelType = selectedTunnelType;
      c.transportType = selectedTransportType;
      c.sshUsername = _isSsh ? sshUsernameController.text.trim() : null;
      c.sshPassword = _isSsh ? sshPasswordController.text : null;
      c.sshPort = _isSsh ? sshPort : null;
      c.socksUsername = socksUsername;
      c.socksPassword = socksPassword;
      c.congestionControl = _isSlipstream ? selectedCongestionControl : null;
      c.keepAliveInterval =
          _isSlipstream ? (keepAlive != null && keepAlive > 0 ? keepAlive : 400) : null;
      c.gsoEnabled = _isSlipstream ? gsoEnabled : null;
      state.updateDnsttConfig(c);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingConfig == null ? 'Config added' : 'Config updated'),
      ),
    );
  }
}
