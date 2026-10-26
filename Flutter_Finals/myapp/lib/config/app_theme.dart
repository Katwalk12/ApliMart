import 'package:flutter/material.dart';

class AppColors {
  static const navyBlue = Color(0xFF0F2C6F);
  static const darkBlue = Color(0xFF1565C0);
  static const primaryBlue = Color(0xFF1976D2);
  static const skyBlue = Color(0xFF29B6F6);
  static const lightBlue = Color(0xFFBBDEFB);
  static const veryLightBlue = Color(0xFFE3F2FD);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF5F5F5);
  static const grey = Color(0xFF9E9E9E);
  static const darkGrey = Color(0xFF424242);
  static const red = Color(0xFFE53935);
  static const saleOrange = Color(0xFFFF6B2B);
  static const green = Color(0xFF43A047);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.skyBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navyBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        scaffoldBackgroundColor: AppColors.offWhite,
        fontFamily: 'Roboto',
      );
}
