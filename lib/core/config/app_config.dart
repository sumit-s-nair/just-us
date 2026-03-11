import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized app configuration — reads from .env file.
abstract final class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
}
