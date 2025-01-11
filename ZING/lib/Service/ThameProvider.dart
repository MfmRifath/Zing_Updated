import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.4),
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      toolbarHeight: 70,
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.openSans(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.openSans(color: Colors.black54, fontSize: 14),
      headlineSmall: GoogleFonts.poppins(color: Colors.blue, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
        shadowColor: Colors.blue.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      ).copyWith(
        elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? 2 : 6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.blue.shade100,
      labelStyle: GoogleFonts.poppins(color: Colors.blue.shade900),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 4,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.blueAccent.withOpacity(0.2),
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      background: Colors.white,
      surface: Colors.blue,
      onPrimary: Colors.white,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey.shade800,
      foregroundColor: Colors.blue,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
      toolbarHeight: 70,
    ),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.openSans(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.openSans(color: Colors.white60, fontSize: 14),
      headlineSmall: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blue,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      ).copyWith(
        elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed) ? 2 : 6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.blueGrey.shade800,
      labelStyle: GoogleFonts.poppins(color: Colors.blue),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 4,
    ),
    cardTheme: CardTheme(
      color: Colors.blueGrey.shade900,
      shadowColor: Colors.black.withOpacity(0.2),
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Colors.blueAccent,
      background: const Color(0xFF121212),
      surface: Colors.blueGrey.shade800,
      onPrimary: Colors.white,
    ),
  );
}