import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../style/theme/dark_theme.dart';
import '../../style/theme/light_theme.dart';

class ThemeController extends GetxController {
  // Initially set to light theme
  Rx<ThemeData> themeData = lightMode.obs;

  // Getter to check if dark mode is active
  bool get isDarkMode => themeData.value == darkMode;

  // Method to toggle between light and dark themes
  void toggleTheme() {
    if (themeData.value == lightMode) {
      themeData.value = darkMode;
    } else {
      themeData.value = lightMode;
    }
  }
}
