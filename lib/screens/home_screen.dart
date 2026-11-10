import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/vpn_service.dart';
import '../models/dnstt_config.dart';
import '../widgets/app_icons.dart';
import '../widgets/world_map.dart';
import 'config_management_screen.dart';
import 'connection_log_screen.dart';
import 'dns_management_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Switches the bottom-navigation tab in MainShell (optional).
  final ValueChanged<int>? onGoTab;

  const HomeScreen({super.key, this.onGoTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum ConnectionMode { vpn, proxy }

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final VpnService _vpnService = VpnService();
  ConnectionMode _connectionMode = ConnectionMode.vpn;
  StreamSubscription<VpnState>? _vpnSub;
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  Timer? _tickTimer;
  Timer? _latencyTimer;
  bool _disconnecting = false;
  bool _autoConnectTried = false;
  bool _measuring = false;
  int? _latencyMs;
  final List<int> _latencyHistory = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _vpnService.init();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    final appState = Provider.of<AppState>(context, listen: false);
    _connectionMode = appState.connectionMode == 'proxy'
        ? ConnectionMode.proxy
        : ConnectionMode.vpn;

    _vpnSub = _vpnService.stateStream.listen((vpnState) {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      switch (vpnState) {
        case VpnState.connecting:
          appState.setConnectionStatus(ConnectionStatus.connecting);
          break;
        case VpnState.connected:
          appState.setConnectionStatus(ConnectionStatus.connected);
          break;
        case VpnState.disconnected:
        case VpnState.disconnecting:
          appState.setConnectionStatus(ConnectionStatus.disconnected);
          break;
        case VpnState.error:
          appState.setConnectionStatus(
              ConnectionStatus.error, 'VPN connection failed');
          break;
      }
    });

    // Session timer + latency refresh while connected.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = Provider.of<AppState>(context, listen: false);
      if (s.connectionStatus == ConnectionStatus.connected) setState(() {});
    });
    _latencyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final s = Provider.of<AppState>(context, listen: false);
      if (s.connectionStatus == ConnectionStatus.connected) {
        _measureLatency(s);
      }
    });

    // Auto Connect preference.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoConnectTried || !mounted) return;
      _autoConnectTried = true;
      final s = Provider.of<AppState>(context, listen: false);
      if (s.autoConnect &&
          s.connectionStatus == ConnectionStatus.disconnected &&
          s.activeConfig != null &&
          s.activeDns != null) {
        _connect(context, s);
      }
    });
  }

  @override
  void dispose() {
    _vpnSub?.cancel();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _tickTimer?.cancel();
    _latencyTimer?.cancel();
    super.dispose();
  }

  Future<void> _measureLatency(AppState state) async {
    final dnsAddress = state.activeDns?.address;
    if (dnsAddress == null || _measuring) return;
    _measuring = true;
    RawDatagramSocket? socket;
    try {
      final target = InternetAddress(dnsAddress);
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final id = _random.nextInt(0xFFFF);
      // Minimal DNS query: root NS lookup header + question.
      final query = <int>[
        id >> 8, id & 0xFF, 0x01, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x01, 0x00, 0x01,
      ];
      final sw = Stopwatch()..start();
      socket.send(query, target, 53);
      final event =
          await socket.first.timeout(const Duration(seconds: 2));
      if (event == RawSocketEvent.read) {
        socket.receive();
        sw.stop();
        if (mounted) {
          setState(() {
            _latencyMs = sw.elapsedMilliseconds;
            _latencyHistory.add(_latencyMs!);
            if (_latencyHistory.length > 30) {
              _latencyHistory.removeAt(0);
            }
          });
        }
      }
    } catch (_) {
      // Network unreachable / timeout: keep last known latency.
    } finally {
      socket?.close();
      _measuring = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context, state),
              const SizedBox(height: 12),
              _buildHero(context, state),
              const SizedBox(height: 66),
              _buildStatusBlock(context, state),
              if (state.connectionStatus == ConnectionStatus.connected) ...[
                const SizedBox(height: 12),
                _buildLatencyCard(context, state),
              ],
              const SizedBox(height: 14),
              _buildDetailsCard(context, state),
              const SizedBox(height: 12),
              _buildTiles(context, state),
            ],
          ),
        );
      },
    );
  }

  // ---------- Top bar ----------
  Widget _buildTopBar(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const HugeIcon(icon: AppIcons.menu),
          onPressed: () => _showAbout(context),
        ),
        const SizedBox(width: 2),
        HugeIcon(icon: AppIcons.shield, color: scheme.primary, size: 24),
        const SizedBox(width: 8),
        const Text(
          'DNS PRO',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              icon: const HugeIcon(icon: AppIcons.bell),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionLogScreen()),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor, width: 1.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: AppIcons.shield,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text('DNS Pro',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Fast & secure DNS tunnel — DNSTT + Slipstream + SSH\nVersion 2.2.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Hero: world map + blended power button ----------
  Widget _buildHero(BuildContext context, AppState state) {
    final isConnected = state.connectionStatus == ConnectionStatus.connected;
    final isConnecting = state.connectionStatus == ConnectionStatus.connecting;
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 198,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF17334D)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                WorldMapView(
                  showRoute: isConnected || isConnecting,
                  accent: scheme.primary,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 96,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bg.withValues(alpha: 0), bg],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -56,
          child: Center(child: _buildPowerButton(context, state)),
        ),
      ],
    );
  }

  Widget _buildPowerButton(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final isConnected = state.connectionStatus == ConnectionStatus.connected;
    final isConnecting = state.connectionStatus == ConnectionStatus.connecting;
    final isError = state.connectionStatus == ConnectionStatus.error;
    final canConnect = state.activeConfig != null && state.activeDns != null;
    final busy = isConnecting || _disconnecting;

    final Color bgColor;
    final Color iconColor;
    if (_disconnecting || isConnecting) {
      bgColor = const Color(0xFFFF9800);
      iconColor = Colors.white;
    } else if (isConnected) {
      bgColor = scheme.primary;
      iconColor = scheme.onPrimary;
    } else if (isError) {
      bgColor = scheme.error;
      iconColor = scheme.onError;
    } else {
      bgColor = scheme.surfaceContainerHighest;
      iconColor = canConnect ? scheme.onSurface : scheme.onSurfaceVariant;
    }

    return SizedBox(
      width: 152,
      height: 152,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isConnected)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final t = 1 + 0.045 * _pulseCtrl.value;
                return Transform.scale(
                  scale: t,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.45),
                          blurRadius: 34,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (busy)
            RotationTransition(
              turns: _spinCtrl,
              child: CustomPaint(
                size: const Size(146, 146),
                painter: _DashedCirclePainter(
                  color: const Color(0xFFFF9800),
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              if (_disconnecting) return;
              if (isConnecting) {
                _cancelConnection(context, state);
              } else if (isConnected) {
                setState(() => _disconnecting = true);
                _disconnect(context, state).whenComplete(() {
                  if (mounted) setState(() => _disconnecting = false);
                });
              } else if (canConnect) {
                _connect(context, state);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: HugeIcon(
                  icon: isError ? AppIcons.refresh : AppIcons.power,
                  color: iconColor,
                  size: 52,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Status ----------
  Widget _buildStatusBlock(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final isConnected = state.connectionStatus == ConnectionStatus.connected;
    final isConnecting = state.connectionStatus == ConnectionStatus.connecting;
    final isError = state.connectionStatus == ConnectionStatus.error;
    final canConnect = state.activeConfig != null && state.activeDns != null;

    final statusColor = _disconnecting
        ? const Color(0xFFFF9800)
        : switch (state.connectionStatus) {
            ConnectionStatus.connected => scheme.primary,
            ConnectionStatus.connecting => const Color(0xFFFF9800),
            ConnectionStatus.error => scheme.error,
            ConnectionStatus.disconnected => scheme.onSurfaceVariant,
          };
    final statusText = _disconnecting
        ? 'Disconnecting…'
        : switch (state.connectionStatus) {
            ConnectionStatus.connected => 'Connected',
            ConnectionStatus.connecting => 'Connecting…',
            ConnectionStatus.error => 'Error',
            ConnectionStatus.disconnected => 'Disconnected',
          };

    String elapsed = '';
    if (isConnected && state.connectedAt != null) {
      final d = DateTime.now().difference(state.connectedAt!);
      elapsed =
          '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 3),
        if (isConnected && elapsed.isNotEmpty)
          Text(
            '$elapsed  •  DNS ${state.activeDns?.address ?? ''}',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        else if (isConnecting)
          Text('Tap to cancel',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
        else if (isError) ...[
          if (state.connectionError != null)
            Text(state.connectionError!,
                style: TextStyle(color: scheme.error, fontSize: 12),
                textAlign: TextAlign.center),
          if (canConnect)
            Text('Tap to retry',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
        ] else if (!canConnect)
          Text('Select a config and DNS server to connect',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center)
        else
          Text('Tap to connect',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }

  // ---------- Live latency ----------
  Widget _buildLatencyCard(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LIVE LATENCY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                HugeIcon(icon: AppIcons.activity, color: scheme.primary, size: 16),
                const SizedBox(width: 5),
                Text(
                  _latencyMs != null ? '$_latencyMs ms' : '…',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
                Text(
                  '  •  ${state.activeDns?.address ?? ''}',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: CustomPaint(
                painter: _LatencyChartPainter(
                  values: _latencyHistory,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Details card ----------
  Widget _buildDetailsCard(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final isDisconnected = state.connectionStatus == ConnectionStatus.disconnected;
    final canConnect = state.activeConfig != null && state.activeDns != null;
    final cfg = state.activeConfig;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _detailRow(
              context,
              icon: AppIcons.sliders,
              color: const Color(0xFFBA68C8),
              label: 'Config',
              child: Text(
                cfg?.name ?? 'No config selected',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: cfg == null ? scheme.onSurfaceVariant : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _detailRow(
              context,
              icon: AppIcons.globe,
              color: const Color(0xFF26A69A),
              label: 'Domain',
              child: Text(
                cfg?.tunnelDomain ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _detailRow(
              context,
              icon: AppIcons.layers,
              color: const Color(0xFF7986CB),
              label: 'Type',
              child: cfg == null
                  ? const Text('—')
                  : Row(
                      children: [
                        PillBadge(
                          label: cfg.tunnelType == TunnelType.ssh ? 'SSH' : 'Socks',
                          color: cfg.tunnelType == TunnelType.ssh
                              ? const Color(0xFFBA68C8)
                              : const Color(0xFF42A5F5),
                        ),
                        const SizedBox(width: 6),
                        PillBadge(
                          label: cfg.isSlipstream ? 'Slipstream' : 'DNSTT',
                          color: cfg.isSlipstream
                              ? const Color(0xFFFFA726)
                              : const Color(0xFF26A69A),
                        ),
                      ],
                    ),
            ),
            _detailRow(
              context,
              icon: AppIcons.server,
              color: const Color(0xFF42A5F5),
              label: 'DNS',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.activeDns != null
                          ? (state.useAutoDns
                              ? '${state.activeDns!.address} (Auto)'
                              : state.activeDns!.address)
                          : 'No DNS selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color:
                            state.activeDns == null ? scheme.onSurfaceVariant : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (state.activeDns?.lastLatencyMs != null)
                    PillBadge(
                      label: '${state.activeDns!.lastLatencyMs} ms',
                      color: const Color(0xFF66BB6A),
                    ),
                ],
              ),
            ),
            if (Platform.isAndroid &&
                isDisconnected &&
                canConnect &&
                state.connectionStatus != ConnectionStatus.error) ...[
              const SizedBox(height: 8),
              _buildModeToggle(context),
            ],
            if (state.connectionStatus == ConnectionStatus.connected &&
                (VpnService.isDesktopPlatform ||
                    _vpnService.isProxyMode ||
                    (_vpnService.isSshTunnelMode &&
                        _connectionMode == ConnectionMode.proxy))) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _buildProxyNotice(context, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required Color color,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          IconChip(icon: icon, color: color, boxSize: 32, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ---------- Mode toggle ----------
  Widget _buildModeToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _modeButton(
            context,
            icon: AppIcons.key,
            label: 'VPN Mode',
            selected: _connectionMode == ConnectionMode.vpn,
            onTap: () {
              setState(() => _connectionMode = ConnectionMode.vpn);
              context.read<AppState>().setConnectionMode('vpn');
            },
          ),
          _modeButton(
            context,
            icon: AppIcons.share,
            label: 'Proxy Mode',
            selected: _connectionMode == ConnectionMode.proxy,
            onTap: () {
              setState(() => _connectionMode = ConnectionMode.proxy);
              context.read<AppState>().setConnectionMode('proxy');
            },
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    BuildContext context, {
    required List<List<dynamic>> icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 16,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Tiles ----------
  Widget _buildTiles(BuildContext context, AppState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _tile(
          context,
          icon: AppIcons.sliders,
          color: const Color(0xFFBA68C8),
          title: 'Configs',
          subtitle:
              '${state.dnsttConfigs.length} configuration${state.dnsttConfigs.length == 1 ? '' : 's'}',
          onTap: () => widget.onGoTab != null
              ? widget.onGoTab!(1)
              : Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConfigManagementScreen())),
        ),
        _tile(
          context,
          icon: AppIcons.server,
          color: const Color(0xFF42A5F5),
          title: 'DNS Servers',
          subtitle: state.useAutoDns
              ? 'Local DNS: ${state.activeDns?.address ?? 'detecting...'}'
              : '${state.dnsServers.length} server${state.dnsServers.length == 1 ? '' : 's'}',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DnsManagementScreen())),
        ),
        _tile(
          context,
          icon: AppIcons.settings,
          color: const Color(0xFFFFA726),
          title: 'Settings',
          subtitle: 'Proxy port: ${state.proxyPort}',
          onTap: () => widget.onGoTab != null
              ? widget.onGoTab!(3)
              : Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        _tile(
          context,
          icon: AppIcons.grid,
          color: const Color(0xFF26A69A),
          title: 'Tools',
          subtitle: 'Extra utilities',
          onTap: () => widget.onGoTab != null
              ? widget.onGoTab!(2)
              : Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ToolsScreen())),
        ),
      ],
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(icon: icon, color: color, boxSize: 42, size: 21),
              const Spacer(),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Proxy notice (connected, proxy modes) ----------
  Widget _buildProxyNotice(BuildContext context, AppState state) {
    final scheme = Theme.of(context).colorScheme;
    final isSshTunnel = _vpnService.isSshTunnelMode;
    final proxyAddress = _vpnService.socksProxyAddress;
    final proxyPort = state.proxyPort;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              HugeIcon(icon: AppIcons.checkCircle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Proxy Active',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSshTunnel ? 'SSH tunnel • Local Proxy Address:' : 'SOCKS5 • Local Proxy Address:',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    proxyAddress,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: proxyAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: HugeIcon(
                        icon: AppIcons.copy, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final telegramUrl =
                    Uri.parse('tg://socks?server=127.0.0.1&port=$proxyPort');
                if (await canLaunchUrl(telegramUrl)) {
                  await launchUrl(telegramUrl);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Telegram is not installed or cannot open the link'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Add Proxy to Telegram'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Connection actions (unchanged behaviour) ----------
  Future<void> _connect(BuildContext context, AppState state) async {
    if (state.useAutoDns) {
      await state.refreshAutoDns();
      if (state.activeDns == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.autoDnsError ?? 'Could not detect system DNS'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final isDesktop = VpnService.isDesktopPlatform;
    final isSshTunnel = state.activeConfig?.tunnelType == TunnelType.ssh;
    final isSlipstream = state.activeConfig?.isSlipstream ?? false;
    final useProxyMode =
        isDesktop || (Platform.isAndroid && _connectionMode == ConnectionMode.proxy);

    String connectionType;
    final protocolName = isSlipstream ? 'Slipstream' : 'DNSTT';
    if (isSshTunnel) {
      connectionType = useProxyMode ? 'SSH tunnel (proxy)' : 'SSH tunnel (VPN)';
    } else {
      connectionType = useProxyMode ? '$protocolName proxy' : '$protocolName VPN';
    }

    if (isSshTunnel) {
      final config = state.activeConfig!;
      if (config.sshUsername == null || config.sshUsername!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SSH username is required. Please configure in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if ((config.sshPassword == null || config.sshPassword!.isEmpty) &&
          (config.sshPrivateKey == null || config.sshPrivateKey!.isEmpty)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SSH password or private key is required.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final needsVpnPermission = !isDesktop && !useProxyMode;
    if (needsVpnPermission) {
      final permissionGranted = await _vpnService.requestPermission();
      if (!permissionGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$connectionType permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    _vpnService.proxyPort = state.proxyPort;

    bool success;

    if (isSshTunnel && useProxyMode) {
      final config = state.activeConfig!;
      success = await _vpnService.connectSshTunnel(
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: config.tunnelDomain,
        publicKey: config.publicKey,
        sshUsername: config.sshUsername!,
        sshPassword: config.sshPassword,
        sshPrivateKey: config.sshPrivateKey,
      );
    } else if (isSshTunnel && !useProxyMode) {
      final config = state.activeConfig!;
      success = await _vpnService.connectSshTunnelVpn(
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: config.tunnelDomain,
        publicKey: config.publicKey,
        sshUsername: config.sshUsername!,
        sshPassword: config.sshPassword,
        sshPrivateKey: config.sshPrivateKey,
      );
    } else if (isSlipstream && useProxyMode) {
      final config = state.activeConfig!;
      success = await _vpnService.connectSlipstreamProxy(
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: config.tunnelDomain,
        proxyPort: state.proxyPort,
        congestionControl: config.congestionControl ?? 'dcubic',
        keepAliveInterval: config.keepAliveInterval ?? 400,
        gso: config.gsoEnabled ?? false,
      );
    } else if (isSlipstream && !useProxyMode) {
      final config = state.activeConfig!;
      success = await _vpnService.connectSlipstream(
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: config.tunnelDomain,
        congestionControl: config.congestionControl ?? 'dcubic',
        keepAliveInterval: config.keepAliveInterval ?? 400,
        gso: config.gsoEnabled ?? false,
      );
    } else if (useProxyMode) {
      success = await _vpnService.connectProxy(
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: state.activeConfig?.tunnelDomain,
        publicKey: state.activeConfig?.publicKey,
        proxyPort: state.proxyPort,
      );
    } else {
      success = await _vpnService.connect(
        proxyHost: '127.0.0.1',
        proxyPort: state.proxyPort,
        dnsServer: state.activeDns?.address ?? '8.8.8.8',
        tunnelDomain: state.activeConfig?.tunnelDomain,
        publicKey: state.activeConfig?.publicKey,
      );
    }

    if (context.mounted) {
      if (success) {
        String successMessage;
        if (isSshTunnel && useProxyMode) {
          successMessage =
              'SSH tunnel (proxy) started on ${_vpnService.socksProxyAddress}';
        } else if (isSshTunnel && !useProxyMode) {
          successMessage = 'SSH tunnel (VPN) connected';
        } else if (useProxyMode || isDesktop) {
          successMessage =
              '$protocolName proxy started on ${_vpnService.socksProxyAddress}';
        } else {
          successMessage = '$protocolName VPN connected';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      } else {
        final error = _vpnService.lastError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error != null
                ? 'Failed to start $connectionType: $error'
                : 'Failed to start $connectionType'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect(BuildContext context, AppState state) async {
    final isDesktop = VpnService.isDesktopPlatform;
    final wasProxyMode = _vpnService.isProxyMode;
    final wasSshTunnelMode = _vpnService.isSshTunnelMode;

    if (wasSshTunnelMode && !isDesktop) {
      await _vpnService.disconnectSshTunnel();
    } else if (wasProxyMode && !isDesktop) {
      await _vpnService.disconnectProxy();
    } else {
      await _vpnService.disconnect();
    }

    if (context.mounted) {
      String disconnectMessage;
      if (wasSshTunnelMode) {
        disconnectMessage = 'SSH tunnel stopped';
      } else if (isDesktop || wasProxyMode) {
        disconnectMessage = 'SOCKS proxy stopped';
      } else {
        disconnectMessage = 'VPN disconnected';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(disconnectMessage)),
      );
    }
  }

  Future<void> _cancelConnection(BuildContext context, AppState state) async {
    if (_vpnService.isSshTunnelMode && !VpnService.isDesktopPlatform) {
      await _vpnService.disconnectSshTunnel();
    } else if (_vpnService.isProxyMode && !VpnService.isDesktopPlatform) {
      await _vpnService.disconnectProxy();
    } else {
      await _vpnService.disconnect();
    }
    state.setConnectionStatus(ConnectionStatus.disconnected);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection cancelled')),
      );
    }
  }
}

/// Rotating dashed ring shown while connecting / disconnecting.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rect = Offset.zero & size;
    const dash = 0.16; // radians
    const gap = 0.13;
    double a = 0;
    while (a < math.pi * 2) {
      canvas.drawArc(rect.deflate(3), a, dash, false, paint);
      a += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

/// Mini latency history chart.
class _LatencyChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _LatencyChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      final p = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 2;
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
      return;
    }
    final maxV = (values.reduce(math.max) * 1.25).clamp(10, 100000).toDouble();
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - 4 - (values[i] / maxV) * (size.height - 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.16));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_LatencyChartPainter old) =>
      old.values != values || old.color != color;
}
