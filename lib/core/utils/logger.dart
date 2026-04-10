import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String tag = 'APP'}) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  static void auth(String message) {
    log(message, tag: 'AUTH');
  }

  static void enterprise(String message) {
    log(message, tag: 'ENTERPRISE');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }
}
