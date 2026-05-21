import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'local';

  static bool get isLocal => appEnv == 'local';

  /// Origin for uploaded media (strip `/api` from API base URL).
  static String get mediaBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base.replaceAll(RegExp(r'/api/?$'), '');
  }

  static String resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$mediaBaseUrl$url';
    }
    return '$mediaBaseUrl/$url';
  }
}
