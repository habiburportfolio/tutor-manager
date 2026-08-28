import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF2F6FED);
const Color kPrimaryDark = Color(0xFF1E4FBF);
const Color kAccentGreen = Color(0xFF1CB981);
const Color kAccentRed = Color(0xFFE5484D);
const Color kAccentOrange = Color(0xFFF5A623);
const Color kBg = Color(0xFFF5F7FB);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'HindSiliguri',
    fontFamilyFallback: const ['Kalpurush', 'NotoSansBengali'],
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kBg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kPrimary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarThemeData(
      // TabBars in this app live inside the blue AppBar (as `bottom:`),
      // so labels must be white/light — not kPrimary blue-on-blue (invisible).
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
