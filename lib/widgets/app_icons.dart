import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Semantic Hugeicons (stroke-rounded) used across DNS Pro.
/// Every constant here was verified against hugeicons 4.4.0.
class AppIcons {
  AppIcons._();

  static const power = HugeIcons.strokeRoundedPower;
  static const shield = HugeIcons.strokeRoundedShield01;
  static const bell = HugeIcons.strokeRoundedNotification01;
  static const menu = HugeIcons.strokeRoundedMenu01;
  static const home = HugeIcons.strokeRoundedHome01;
  static const sliders = HugeIcons.strokeRoundedSlidersHorizontal;
  static const settings = HugeIcons.strokeRoundedSettings02;
  static const globe = HugeIcons.strokeRoundedGlobe;
  static const server = HugeIcons.strokeRoundedServerStack01;
  static const key = HugeIcons.strokeRoundedKey01;
  static const share = HugeIcons.strokeRoundedShare08;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const add = HugeIcons.strokeRoundedAdd01;
  static const edit = HugeIcons.strokeRoundedEdit02;
  static const delete = HugeIcons.strokeRoundedDelete02;
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const tick = HugeIcons.strokeRoundedTick02;
  static const checkCircle = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const copy = HugeIcons.strokeRoundedCopy01;
  static const clock = HugeIcons.strokeRoundedClock01;
  static const activity = HugeIcons.strokeRoundedActivity01;
  static const file = HugeIcons.strokeRoundedFile01;
  static const note = HugeIcons.strokeRoundedNote01;
  static const layers = HugeIcons.strokeRoundedLayers01;
  static const grid = HugeIcons.strokeRoundedDashboardSquare01;
  static const wifi = HugeIcons.strokeRoundedWifi01;
  static const testTube = HugeIcons.strokeRoundedTestTube01;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const cancel = HugeIcons.strokeRoundedCancel01;
  static const arrowUp = HugeIcons.strokeRoundedArrowUp01;
  static const arrowDown = HugeIcons.strokeRoundedArrowDown01;
  static const refresh = HugeIcons.strokeRoundedRefresh01;
  static const location = HugeIcons.strokeRoundedLocation01;
  static const route = HugeIcons.strokeRoundedRoute01;
  static const earth = HugeIcons.strokeRoundedEarth;
  static const paint = HugeIcons.strokeRoundedPaintBoard;
  static const moon = HugeIcons.strokeRoundedMoon01;
  static const sun = HugeIcons.strokeRoundedSun01;
  static const droplet = HugeIcons.strokeRoundedDroplet;
  static const leaf = HugeIcons.strokeRoundedLeaf01;
  static const database = HugeIcons.strokeRoundedDatabase01;
  static const download = HugeIcons.strokeRoundedDownload01;
  static const upload = HugeIcons.strokeRoundedUpload01;
}

/// Rounded tinted icon chip used in rows, tiles and settings.
class IconChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final double size;
  final double boxSize;

  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 19,
    this.boxSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(boxSize * 0.34),
      ),
      child: Center(child: HugeIcon(icon: icon, color: color, size: size)),
    );
  }
}

/// Small pill badge (Socks / Slipstream / DNSTT / SSH).
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;

  const PillBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
