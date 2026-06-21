import 'package:flutter/foundation.dart';

class Logger {
  static void info(String message, {String prefix = "APP"}) {
    if (kDebugMode) {
      print("[$prefix] INFO: $message");
    }
  }

  static void error(String message, {String prefix = "APP", dynamic error}) {
    if (kDebugMode) {
      print("[$prefix] ERROR: $message${error != null ? ' - $error' : ''}");
    }
  }

  static void debug(String message, {String prefix = "APP"}) {
    if (kDebugMode) {
      print("[$prefix] DEBUG: $message");
    }
  }
}
