import 'package:uuid/uuid.dart';

/// Transport type enumeration - the underlying tunnel protocol
/// - dnstt: Original DNSTT protocol (DNS TXT + KCP + Noise)
/// - slipstream: Slipstream protocol (QUIC-over-DNS, ~5x faster)
enum TransportType {
  dnstt,
  slipstream,
}

/// Tunnel type enumeration - what the server forwards to
/// - socks5: Server configured to forward to SOCKS5 proxy (standard DNSTT)
/// - ssh: Server configured to forward to SSH server (port 22)
///
/// For SSH mode:
/// 1. DNSTT creates TCP tunnel to SSH server (127.0.0.1:<port> -> SSH)
/// 2. App's SSH client connects through tunnel using credentials from config
/// 3. SSH dynamic port forwarding creates local SOCKS5 proxy
/// 4. User apps connect to the local SOCKS5 proxy (port configurable in settings)
enum TunnelType {
  socks5,
  ssh,
}

class DnsttConfig {
  final String id;
  String name;
  String publicKey;
  String tunnelDomain;

  /// Transport type - the underlying tunnel protocol
  TransportType transportType;

  /// Tunnel type - indicates what the server is configured for
  TunnelType tunnelType;

  /// SSH settings (only used when tunnelType is ssh)
  /// The SSH server is accessed through the DNSTT tunnel
  String? sshUsername;
  String? sshPassword;
  String? sshPrivateKey;

  /// SSH server port as given by the provider (default 22).
  /// Together with [sshHost] this is the target the tunnel is asked to
  /// reach (e.g. 13.212.225.4:22 in provider configs).
  int? sshPort;

  /// SSH target host (IP or hostname) reached THROUGH the tunnel.
  /// Provider SSH configs specify it separately from the tunnel domain
  /// (e.g. tunnel domain ssh.example.com, target 13.212.225.4). When set,
  /// the SSH client connects to this host:port via the tunnel's SOCKS
  /// interface; when empty, the tunnel's raw stream is used (servers
  /// that forward every stream straight to their SSH daemon).
  String? sshHost;

  /// SOCKS5 username/password authentication (only used when
  /// tunnelType is socks5). Used by the VPN service's SOCKS5 client when
  /// the server-side SOCKS proxy requires RFC 1929 authentication.
  String? socksUsername;
  String? socksPassword;

  /// Slipstream-specific settings (only used when transportType is slipstream)
  /// Congestion control algorithm: "bbr" or "dcubic" (default: "dcubic")
  String? congestionControl;
  /// Keep-alive interval in milliseconds (default: 400)
  int? keepAliveInterval;
  /// Generic Segmentation Offload (default: false)
  bool? gsoEnabled;

  DnsttConfig({
    String? id,
    required this.name,
    required this.publicKey,
    required this.tunnelDomain,
    this.transportType = TransportType.dnstt,
    this.tunnelType = TunnelType.socks5,
    this.sshUsername,
    this.sshPassword,
    this.sshPrivateKey,
    this.sshPort,
    this.sshHost,
    this.socksUsername,
    this.socksPassword,
    this.congestionControl,
    this.keepAliveInterval,
    this.gsoEnabled,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'publicKey': publicKey,
        'tunnelDomain': tunnelDomain,
        'transportType': transportType.name,
        'tunnelType': tunnelType.name,
        'sshUsername': sshUsername,
        'sshPassword': sshPassword,
        'sshPrivateKey': sshPrivateKey,
        'sshPort': sshPort,
        'sshHost': sshHost,
        'socksUsername': socksUsername,
        'socksPassword': socksPassword,
        'congestionControl': congestionControl,
        'keepAliveInterval': keepAliveInterval,
        'gsoEnabled': gsoEnabled,
      };

  factory DnsttConfig.fromJson(Map<String, dynamic> json) => DnsttConfig(
        id: json['id'],
        name: json['name'],
        publicKey: json['publicKey'] ?? '',
        tunnelDomain: json['tunnelDomain'],
        transportType: _parseTransportType(json['transportType']),
        tunnelType: _parseTunnelType(json['tunnelType']),
        sshUsername: json['sshUsername'],
        sshPassword: json['sshPassword'],
        sshPrivateKey: json['sshPrivateKey'],
        sshPort: json['sshPort'] is int
            ? json['sshPort']
            : int.tryParse(json['sshPort']?.toString() ?? ''),
        sshHost: json['sshHost'],
        socksUsername: json['socksUsername'],
        socksPassword: json['socksPassword'],
        congestionControl: json['congestionControl'],
        keepAliveInterval: json['keepAliveInterval'],
        gsoEnabled: json['gsoEnabled'],
      );

  static TransportType _parseTransportType(dynamic value) {
    if (value == null) return TransportType.dnstt;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'slipstream':
          return TransportType.slipstream;
        case 'dnstt':
        default:
          return TransportType.dnstt;
      }
    }
    return TransportType.dnstt;
  }

  static TunnelType _parseTunnelType(dynamic value) {
    if (value == null) return TunnelType.socks5;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'ssh':
          return TunnelType.ssh;
        case 'socks5':
        default:
          return TunnelType.socks5;
      }
    }
    return TunnelType.socks5;
  }

  /// Whether this config uses the Slipstream transport
  bool get isSlipstream => transportType == TransportType.slipstream;

  /// Basic validation
  /// Slipstream configs don't need publicKey, but DNSTT configs do
  bool get isValid {
    if (tunnelDomain.isEmpty) return false;
    if (isSlipstream) return true;
    return publicKey.isNotEmpty && publicKey.length == 64;
  }

  /// Check if SSH settings are valid (when tunnel type is ssh)
  bool get isSshValid =>
      tunnelType != TunnelType.ssh ||
      (sshUsername != null &&
          sshUsername!.isNotEmpty &&
          (sshPassword != null && sshPassword!.isNotEmpty ||
              sshPrivateKey != null && sshPrivateKey!.isNotEmpty));

  /// Full validation including SSH settings
  bool get isFullyValid => isValid && isSshValid;

  /// Copy with method for easy modification
  DnsttConfig copyWith({
    String? id,
    String? name,
    String? publicKey,
    String? tunnelDomain,
    TransportType? transportType,
    TunnelType? tunnelType,
    String? sshUsername,
    String? sshPassword,
    String? sshPrivateKey,
    int? sshPort,
    String? sshHost,
    String? socksUsername,
    String? socksPassword,
    String? congestionControl,
    int? keepAliveInterval,
    bool? gsoEnabled,
  }) {
    return DnsttConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      tunnelDomain: tunnelDomain ?? this.tunnelDomain,
      transportType: transportType ?? this.transportType,
      tunnelType: tunnelType ?? this.tunnelType,
      sshUsername: sshUsername ?? this.sshUsername,
      sshPassword: sshPassword ?? this.sshPassword,
      sshPrivateKey: sshPrivateKey ?? this.sshPrivateKey,
      sshPort: sshPort ?? this.sshPort,
      sshHost: sshHost ?? this.sshHost,
      socksUsername: socksUsername ?? this.socksUsername,
      socksPassword: socksPassword ?? this.socksPassword,
      congestionControl: congestionControl ?? this.congestionControl,
      keepAliveInterval: keepAliveInterval ?? this.keepAliveInterval,
      gsoEnabled: gsoEnabled ?? this.gsoEnabled,
    );
  }
}
