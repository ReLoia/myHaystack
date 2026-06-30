import 'package:flutter/foundation.dart';

class Logger {
  static void info(String message, {String prefix = "APP"}) {
    debugPrint("[$prefix] INFO: $message");
  }

  static void error(String message, {String prefix = "APP", dynamic error}) {
    debugPrint("[$prefix] ERROR: $message${error != null ? ' - $error' : ''}");
  }

  static void debug(String message, {String prefix = "APP"}) {
    debugPrint("[$prefix] DEBUG: $message");
  }
}
