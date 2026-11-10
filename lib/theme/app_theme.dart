import 'package:flutter/material.dart';

/// DNS Pro theme variants (see Settings > App Theme).
enum AppThemeOption { light, dark, amoled, purple, blue, green }

extension AppThemeOptionX on AppThemeOption {
  String get label => switch (this) {
        AppThemeOption.light => 'Light',
        AppThemeOption.dark => 'Dark',
        AppThemeOption.amoled => 'AMOLED',
        AppThemeOption.purple => 'Purple',
        AppThemeOption.blue => 'Blue',
        AppThemeOption.green => 'Green',
      };

  Color get seed => switch (this) {
        AppThemeOption.light => const Color(0xFF7C4DFF),
        AppThemeOption.dark => const Color(0xFF8B5CF6),
        AppThemeOption.amoled => const Color(0xFF00E676),
        AppThemeOption.purple => const Color(0xFFA855F7),
        AppThemeOption.blue => const Color(0xFF2196F3),
        AppThemeOption.green => const Color(0xFF00C853),
      };

  bool get isLight => this == AppThemeOption.light;

  /// Scaffold / page background.
  Color get bg => switch (this) {
        AppThemeOption.light => const Color(0xFFF5F4FA),
        AppThemeOption.dark => const Color(0xFF101018),
        AppThemeOption.amoled => const Color(0xFF000000),
        AppThemeOption.purple => const Color(0xFF190735),
        AppThemeOption.blue => const Color(0xFF04101F),
        AppThemeOption.green => const Color(0xFF03130B),
      };

  /// Card surface.
  Color get card => switch (this) {
        AppThemeOption.light => const Color(0xFFFFFFFF),
        AppThemeOption.dark => const Color(0xFF1B1B26),
        AppThemeOption.amoled => const Color(0xFF0E0E11),
        AppThemeOption.purple => const Color(0xFF2A1150),
        AppThemeOption.blue => const Color(0xFF0A2138),
        AppThemeOption.green => const Color(0xFF0A2417),
      };

  /// Raised / inset surface (segmented control track, fields).
  Color get cardAlt => switch (this) {
        AppThemeOption.light => const Color(0xFFEFEAFB),
        AppThemeOption.dark => const Color(0xFF262633),
        AppThemeOption.amoled => const Color(0xFF17171B),
        AppThemeOption.purple => const Color(0xFF37186A),
        AppThemeOption.blue => const Color(0xFF10304F),
        AppThemeOption.green => const Color(0xFF113620),
      };

  static AppThemeOption fromName(String? name) {
    return AppThemeOption.values.firstWhere(
      (o) => o.name == name,
      orElse: () => AppThemeOption.amoled,
    );
  }
}

/// Fully-rounded Material 3 theme for a variant.
ThemeData buildAppTheme(AppThemeOption option) {
  final brightness = option.isLight ? Brightness.light : Brightness.dark;
  var scheme = ColorScheme.fromSeed(seedColor: option.seed, brightness: brightness);
  scheme = scheme.copyWith(
    surface: option.card,
    onSurface: option.isLight ? const Color(0xFF17131F) : Colors.white,
    surfaceContainerLowest: option.bg,
    surfaceContainerLow: option.card,
    surfaceContainer: option.card,
    surfaceContainerHigh: option.cardAlt,
    surfaceContainerHighest: option.cardAlt,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: option.bg,
    brightness: brightness,
  );

  final borderSide = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45));

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: option.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: option.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: borderSide,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: option.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const StadiumBorder()),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: borderSide,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: option.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: option.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: option.bg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          size: 24,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : null),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.45),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
  );
}
