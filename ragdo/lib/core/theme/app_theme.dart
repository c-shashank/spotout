import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.sourceCodeProTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.primaryText,
    ),
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.primaryText,
        fontSize: 12,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.primaryText,
        fontSize: 12,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.secondaryText,
        fontSize: 11,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.sourceCodePro(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        color: AppColors.primaryText,
        letterSpacing: 0.1 * 22,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.sourceCodePro(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        textStyle: GoogleFonts.sourceCodePro(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: GoogleFonts.sourceCodePro(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.cardDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: GoogleFonts.sourceCodePro(
        color: AppColors.secondaryText,
        fontSize: 12,
      ),
      hintStyle: GoogleFonts.sourceCodePro(
        color: AppColors.grey,
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tagPillBg,
      labelStyle: GoogleFonts.sourceCodePro(
        color: AppColors.tagPillText,
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: const StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardDivider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.grey,
      selectedLabelStyle: GoogleFonts.sourceCodePro(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.sourceCodePro(
        fontSize: 11,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: GoogleFonts.sourceCodePro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.sourceCodePro(
        fontSize: 12,
      ),
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.secondaryText,
      indicatorColor: AppColors.accent,
    ),
  );
}
