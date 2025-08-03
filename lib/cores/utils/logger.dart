import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    if (kDebugMode) {
      print('🟢 LOG: $message');
    }
  }

  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      print('🔴 ERROR: $message');
      if (error != null) print('🔻 Detail: $error');
    }
  }
}
