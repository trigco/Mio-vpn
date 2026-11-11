import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Continent outlines in a 320x172 equirectangular space, drawn from real
/// coastal geography so countries/continents stay recognizable.
const List<String> _landRaw = [
  // North America
  '13,12 20,8 31,9 40,11 49,8 58,11 67,12 76,11 80,14 78,18 84,14 87,9 89,6 92,12 91,19 86,21 91,24 96,24 100,24 103,21 107,27 103,34 101,39 98,43 94,46 93,51 90,53 89,56 88,63 85,59 84,57 81,57 77,57 74,59 74,64 76,71 80,76 86,82 90,82 84,77 78,75 74,74 69,71 67,69 64,65 62,64 59,58 56,53 53,51 52,47 50,40 50,36 47,32 44,27 40,24 31,21 25,24 21,25 16,21 13,21 11,15',
  // South America
  '90,82 92,84 93,81 96,78 103,81 107,83 114,87 116,93 121,95 124,96 129,102 125,108 124,119 119,123 114,132 109,138 105,139 102,141 102,146 100,152 100,157 97,157 94,152 94,145 95,136 97,128 98,120 98,114 93,110 92,107 90,101 88,97 89,91 92,88 92,84',
  // Greenland
  '119,21 123,15 132,12 140,9 142,2 131,0 116,1 111,7 112,15 114,21',
  // Eurasia
  '152,49 152,42 158,36 160,33 163,30 167,27 167,24 164,21 164,18 169,15 172,13 176,11 182,8 188,9 196,12 203,12 212,11 220,9 229,7 240,4 252,1 262,5 274,7 286,7 298,9 309,11 318,14 320,17 311,21 296,29 286,28 285,36 284,43 280,42 278,42 273,45 275,50 270,50 267,55 268,59 265,63 260,66 256,71 257,77 254,82 252,85 249,83 247,77 246,74 244,72 241,66 239,66 237,69 234,71 231,75 231,81 228,83 227,77 224,70 222,66 219,63 214,63 211,60 208,62 204,58 204,62 207,63 210,64 213,66 211,71 207,75 203,76 199,78 197,75 196,69 193,64 191,59 190,56 192,50 187,50 184,49 180,50 177,45 173,44 171,40 167,40 163,42 160,46 158,49',
  // Africa
  '155,51 152,56 152,60 147,65 145,72 148,81 153,85 157,87 163,85 165,88 168,94 171,100 172,107 171,114 173,119 174,126 175,131 177,133 178,134 183,132 188,127 191,122 192,116 196,110 197,104 196,98 197,93 201,87 205,81 203,79 198,79 196,75 194,69 192,64 190,59 189,56 187,56 182,55 178,55 173,55 170,52 169,49 164,49 160,50 158,51',
  // Madagascar
  '199,112 202,110 204,114 202,121 200,122 199,116',
  // Australia
  '261,118 261,123 262,129 265,134 270,132 275,130 277,130 280,134 283,134 285,138 289,138 291,138 293,136 296,130 296,125 294,121 293,116 290,115 289,110 286,106 286,113 284,113 281,110 281,107 280,107 277,106 275,109 272,109 268,113 265,116',
  // UK
  '156,33 159,29 161,32 159,36 157,36',
  // Japan
  '285,50 287,44 289,39 286,41 283,46',
  // Sumatra
  '245,87 249,93 253,98 254,99 251,96 246,89',
  // Borneo
  '257,91 261,89 264,85 266,90 264,95 261,96 258,94',
  // Java
  '253,100 262,101 262,103 253,102',
  // Sulawesi
  '265,90 269,87 270,91 267,95 265,93',
  // New Guinea
  '277,94 281,95 285,96 290,100 291,103 286,102 282,97 277,96',
];

final List<List<Offset>> _land = _landRaw.map((raw) {
  return raw.split(' ').map((pair) {
    final parts = pair.split(',');
    return Offset(double.parse(parts[0]), double.parse(parts[1]));
  }).toList();
}).toList();

/// Network node points (map coords) with their glow colors.
const List<(Offset, Color)> _nodes = [
  (Offset(94, 61), Color(0xFF38BDF8)),
  (Offset(104, 104), Color(0xFF38BDF8)),
  (Offset(160, 50), Color(0xFF818CF8)),
  (Offset(178, 84), Color(0xFFC084FC)),
  (Offset(205, 58), Color(0xFFE879F9)),
  (Offset(283, 51), Color(0xFFF472B6)),
  (Offset(279, 110), Color(0xFFF472B6)),
  (Offset(255, 32), Color(0xFFFB7185)),
];

/// Decorative network arcs: (start, control, end) in map coords.
const List<(Offset, Offset, Offset)> _netArcs = [
  (Offset(94, 61), Offset(128, 28), Offset(160, 50)),
  (Offset(160, 50), Offset(168, 68), Offset(178, 84)),
  (Offset(178, 84), Offset(228, 122), Offset(279, 110)),
  (Offset(205, 58), Offset(222, 44), Offset(240, 63)),
  (Offset(240, 63), Offset(264, 38), Offset(283, 51)),
  (Offset(94, 61), Offset(92, 86), Offset(104, 104)),
  (Offset(160, 50), Offset(205, 20), Offset(262, 30)),
];

/// User location (Dhaka) and fallback server location (Singapore) in
/// map coords. The map space is a plain equirectangular projection:
/// x = (lon + 180) * 320 / 360, y = (90 - lat) * 172 / 180
/// (Dhaka 23.8N 90.4E -> 240,63 and Singapore 1.35N 103.8E -> 252,85).
const Offset _homePin = Offset(240, 63);
const Offset _serverPin = Offset(252, 85);

Offset latLonToMap(double lat, double lon) =>
    Offset((lon + 180) * 320 / 360, (90 - lat) * 172 / 180);

Path _routePath(Offset serverPin) {
  final mid = Offset(
    (_homePin.dx + serverPin.dx) / 2,
    (_homePin.dy + serverPin.dy) / 2,
  );
  final dist = (serverPin - _homePin).distance;
  final control = Offset(mid.dx, mid.dy - 6 - dist * 0.22);
  final p = Path();
  p.moveTo(_homePin.dx, _homePin.dy);
  p.quadraticBezierTo(control.dx, control.dy, serverPin.dx, serverPin.dy);
  return p;
}

Path _landPath() {
  final path = Path();
  for (final poly in _land) {
    path.moveTo(poly.first.dx, poly.first.dy);
    for (final pt in poly.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();
  }
  return path;
}

/// Premium hero world map.
///
/// When [showRoute] is false the camera rests on the whole world. Turning it
/// on gently zooms toward the Dhaka -> server route, draws the route arc and
/// loops a travelling dot; turning it off animates the camera back.
class WorldMapView extends StatefulWidget {
  final bool showRoute;
  final Color accent;

  /// Real server location (from the connected config's domain). When
  /// null, the route falls back to the default Singapore pin.
  final double? serverLat;
  final double? serverLon;

  const WorldMapView({
    super.key,
    required this.showRoute,
    required this.accent,
    this.serverLat,
    this.serverLon,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView>
    with TickerProviderStateMixin {
  late final AnimationController _focusCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      value: widget.showRoute ? 1 : 0,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(WorldMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRoute != oldWidget.showRoute) {
      if (widget.showRoute) {
        _focusCtrl.forward();
      } else {
        _focusCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_focusCtrl, _pulseCtrl]),
      builder: (context, _) {
        final eased = Curves.easeInOutCubic.transform(_focusCtrl.value);
        final serverPin = (widget.serverLat != null && widget.serverLon != null)
            ? latLonToMap(widget.serverLat!, widget.serverLon!)
            : _serverPin;
        return CustomPaint(
          painter: _WorldMapPainter(
            focus: eased,
            pulse: _pulseCtrl.value,
            accent: widget.accent,
            serverPin: serverPin,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  final double focus;
  final double pulse;
  final Color accent;
  final Offset serverPin;

  _WorldMapPainter({
    required this.focus,
    required this.pulse,
    required this.accent,
    required this.serverPin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Deep-space blue backdrop (the map keeps its own premium palette
    // in every app theme, like the reference design).
    final bgPaint = Paint()..color = const Color(0xFF050F1E);
    canvas.drawRect(Offset.zero & size, bgPaint);
    final glowRect = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.42),
      width: size.width * 1.1,
      height: size.height * 1.3,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..color = const Color(0xFF0B2A4A).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // Camera: cover-fit the 320x172 map, then ease toward the route.
    final cover = math.max(size.width / 320, size.height / 172) * 1.04;
    final scale = cover * (1 + 0.45 * focus);
    final routeMidX = (_homePin.dx + serverPin.dx) / 2;
    final routeMidY = (_homePin.dy + serverPin.dy) / 2;
    final cx = 160 + (routeMidX - 160) * focus;
    final cy = 86 + (routeMidY - 86) * focus;
    canvas.save();
    canvas.translate(size.width / 2 - cx * scale, size.height / 2 - cy * scale);
    canvas.scale(scale);

    final land = _landPath();

    // Land glow.
    canvas.drawPath(
      land,
      Paint()
        ..color = const Color(0xFFF472B6).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Land fill: west (cyan) -> east (pink) gradient.
    final gradient = const LinearGradient(
      colors: [
        Color(0xFF38BDF8),
        Color(0xFF818CF8),
        Color(0xFFC084FC),
        Color(0xFFF472B6),
        Color(0xFFFB7185),
      ],
      stops: [0, 0.35, 0.6, 0.85, 1],
    );
    canvas.drawPath(
      land,
      Paint()
        ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 320, 172))
        ..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      land,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 / scale * 1.4
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    // Dot texture clipped to the land.
    canvas.save();
    canvas.clipPath(land);
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (double x = 2; x < 320; x += 5) {
      for (double y = 2; y < 172; y += 5) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
    canvas.restore();

    // Network arcs (flowing dashes).
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFBED7FF).withValues(alpha: 0.38);
    for (final (a, c, b) in _netArcs) {
      final p = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
      for (final metric in p.computeMetrics()) {
        const dash = 3.0, gap = 4.0;
        double d = -pulse * 14 % (dash + gap);
        while (d < metric.length) {
          final start = math.max(d, 0.0);
          final end = math.min(d + dash, metric.length);
          if (end > start) {
            canvas.drawPath(metric.extractPath(start, end), arcPaint);
          }
          d += dash + gap;
        }
      }
    }

    // Nodes.
    for (int i = 0; i < _nodes.length; i++) {
      final (pos, color) = _nodes[i];
      final phase = (pulse + i * 0.13) % 1.0;
      final haloR = 4.5 + 3 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
      canvas.drawCircle(
        pos,
        haloR,
        Paint()..color = color.withValues(alpha: 0.30),
      );
      canvas.drawCircle(pos, 2.1, Paint()..color = Colors.white);
    }

    // Route (faint full arc + animated solid arc).
    final route = _routePath(serverPin);
    final faintPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFA0C8F5).withValues(alpha: 0.45);
    for (final metric in route.computeMetrics()) {
      const dash = 3.0, gap = 4.0;
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          faintPaint,
        );
        d += dash + gap;
      }
    }
    if (focus > 0.02) {
      final solidPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = accent;
      for (final metric in route.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * focus), solidPaint);
        if (focus > 0.95) {
          final pos = metric.getTangentForOffset(metric.length * pulse)?.position;
          if (pos != null) {
            canvas.drawCircle(
              pos,
              5,
              Paint()..color = Colors.white.withValues(alpha: 0.35),
            );
            canvas.drawCircle(pos, 3.2, Paint()..color = Colors.white);
          }
        }
      }
    }

    // Pins.
    _drawPin(canvas, _homePin, const Color(0xFF38BDF8), 0);
    if (focus > 0.02) {
      _drawPin(canvas, serverPin, const Color(0xFFF472B6), 0.35);
    }

    canvas.restore();
  }

  void _drawPin(Canvas canvas, Offset pos, Color color, double phaseOffset) {
    final phase = (pulse + phaseOffset) % 1.0;
    final ringR = 6 + 6 * phase;
    canvas.drawCircle(
      pos,
      ringR,
      Paint()..color = color.withValues(alpha: 0.28 * (1 - phase)),
    );
    canvas.drawCircle(pos, 3.6, Paint()..color = color);
    canvas.drawCircle(
      pos,
      3.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_WorldMapPainter old) =>
      old.focus != focus ||
      old.pulse != pulse ||
      old.accent != accent ||
      old.serverPin != serverPin;
}
