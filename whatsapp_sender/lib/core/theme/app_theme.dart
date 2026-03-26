import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema Material 3 com a paleta de cores WhatsApp.
final class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.waGreen,
          primary: AppColors.waGreen,
          secondary: AppColors.waMidGreen,
          surface: AppColors.cardBg,
          error: AppColors.red,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: const Color(0xFF111111),
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.waDarkGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.white,
          unselectedLabelColor: Color(0xFFB2DFDB),
          indicatorColor: AppColors.waGreen,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.waMidGreen, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF222222)),
          labelLarge: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.waGreen,
          linearTrackColor: Color(0xFFDDDDDD),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
        ),
      );
}
