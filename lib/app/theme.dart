import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const indigo = Color(0xFF92C4E7);
const navy = Color(0xFF152B48);
const teal = Color(0xFF91C8C4);
const amber = Color(0xFFEAC16C);
const paperCream = Color(0xFFFFF1D9);
const paperBlue = Color(0xFFB9D9F0);
const paperInk = Color(0xFF142641);
const paperMidnight = Color(0xFF08223B);

Color answeredColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF74DDA2)
    : const Color(0xFF176A40);

class PapercutShape extends OutlinedBorder {
  const PapercutShape({super.side = BorderSide.none});
  static Path cutPath(Rect r) => Path()
    ..moveTo(r.left + 21, r.top)
    ..lineTo(r.right - 24, r.top + 1)
    ..quadraticBezierTo(r.right, r.top + 1, r.right, r.top + 23)
    ..lineTo(r.right - 1, r.bottom - 19)
    ..quadraticBezierTo(r.right - 1, r.bottom, r.right - 21, r.bottom)
    ..lineTo(r.left + 18, r.bottom - 1)
    ..quadraticBezierTo(r.left, r.bottom - 1, r.left, r.bottom - 21)
    ..lineTo(r.left + 1, r.top + 20)
    ..quadraticBezierTo(r.left + 1, r.top, r.left + 21, r.top)
    ..close();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => cutPath(rect);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      cutPath(rect.deflate(side.width));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid && side.width > 0) {
      canvas.drawPath(cutPath(rect.deflate(side.width / 2)), side.toPaint());
    }
  }

  @override
  PapercutShape copyWith({BorderSide? side}) =>
      PapercutShape(side: side ?? this.side);
  @override
  PapercutShape scale(double t) => PapercutShape(side: side.scale(t));
}

ThemeData journeyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? paperCream : paperInk;
  final muted = dark ? const Color(0xFFB1C3D8) : const Color(0xFF55677A);
  final background = dark ? paperMidnight : const Color(0xFFF1E8D9);
  final surface = dark ? const Color(0xFF1C3553) : const Color(0xFFFFF8EB);
  final outline = dark ? const Color(0xFF3C5875) : const Color(0xFFC8BDAA);
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xFF365F8A),
    brightness: brightness,
    primary: dark ? paperBlue : const Color(0xFF244D77),
    onPrimary: dark ? paperInk : paperCream,
    secondary: dark ? teal : const Color(0xFF3D6D71),
    tertiary: dark ? amber : const Color(0xFF8B5E12),
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: outline,
    outlineVariant: outline.withValues(alpha: .65),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    fontFamily: 'PlusJakarta',
    brightness: brightness,
    scaffoldBackgroundColor: background,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -.45,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 62,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'PlusJakarta',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x66040812),
      elevation: dark ? 5 : 3,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: PapercutShape(
        side: BorderSide(color: outline.withValues(alpha: .65), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF172D48) : const Color(0xFFE9E0D0),
      hintStyle: TextStyle(color: muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        elevation: 3,
        shadowColor: const Color(0x66040914),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakarta',
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: dark ? const Color(0xFF385D7F) : const Color(0xFFCDDFEB),
      side: BorderSide(color: outline.withValues(alpha: .7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(
        fontFamily: 'PlusJakarta',
        color: ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'PlusJakarta',
        color: ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 82,
      backgroundColor: dark ? const Color(0xFF152B46) : const Color(0xFFFFF8EB),
      surfaceTintColor: Colors.transparent,
      indicatorColor: dark ? const Color(0xFF355777) : const Color(0xFFD3E0E8),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'PlusJakarta',
          fontSize: 10,
          color: s.contains(WidgetState.selected) ? ink : muted,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: outline,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(
      color: outline.withValues(alpha: .6),
      space: 24,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: outline.withValues(alpha: .35),
    ),
  );
}
