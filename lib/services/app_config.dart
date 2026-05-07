import 'package:flutter/foundation.dart';

class AppConfig {
  // Priority:
  // 1) --dart-define=API_BASE_URL=...
  // 2) Web default: localhost
  // 3) Android emulator default: 10.0.2.2
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.0.2.2:5000';
  }
}

