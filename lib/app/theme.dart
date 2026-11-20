import 'package:material_ui/material_ui.dart';

const indigo = Color(0xFF4653D9);
const navy = Color(0xFF14243A);
const teal = Color(0xFF087F8C);
const amber = Color(0xFFD97706);
ThemeData journeyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: indigo,
    brightness: brightness,
    primary: dark ? const Color(0xFFB7BEFF) : indigo,
    secondary: dark ? const Color(0xFF6ED2D5) : teal,
    surface: dark ? const Color(0xFF172131) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    fontFamily: 'PlusJakarta',
    brightness: brightness,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF101824)
        : const Color(0xFFF7F9FC),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: dark ? Colors.white : navy,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -.6,
        color: dark ? Colors.white : navy,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: dark ? Colors.white : navy,
      ),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.65),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.6),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101824) : const Color(0xFFF7F9FC),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'PlusJakarta',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: dark ? Colors.white : navy,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xFF2A3748) : const Color(0xFFE9EDF4),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202C3E) : const Color(0xFFF0F3F9),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: colors.surface,
      indicatorColor: dark ? const Color(0xFF343C76) : const Color(0xFFE9EBFF),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? const Color(0xFF2A3748) : const Color(0xFFE9EDF4),
      space: 24,
    ),
  );
}
