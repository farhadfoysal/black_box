import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'OMR Management System';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color secondaryColor = Color(0xFF34495E);
  static const Color accentColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color infoColor = Color(0xFF3498DB);

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;

  // OMR Settings
  static const int maxQuestions = 100;
  static const int minQuestions = 10;
  static const List<String> answerOptions = ['A', 'B', 'C', 'D'];
  static const double passingPercentage = 60.0;

  // Storage Keys
  static const String omrSheetsKey = 'omr_sheets';
  static const String studentsKey = 'students';
  static const String resultsKey = 'exam_results';
  static const String coursesKey = 'courses';
  static const String settingsKey = 'app_settings';
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}