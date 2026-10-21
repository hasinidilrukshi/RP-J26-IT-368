import 'package:flutter/foundation.dart';

/// Backend location – chosen automatically:
///
/// * Chrome / web (flutter run -d chrome) -> http://localhost:8000
/// * Android emulator                     -> http://10.0.2.2:8000
/// * iOS simulator / desktop              -> http://127.0.0.1:8000
/// * Real phone: pass your PC's Wi-Fi IP:
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static const Duration timeout = Duration(seconds: 60);

  /// Turns a backend relative path such as `/uploads/abc.jpg` into a full URL.
  static String? absolute(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}