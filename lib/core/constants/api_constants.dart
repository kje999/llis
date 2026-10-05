import 'package:flutter/foundation.dart';
import 'package:my_lucky_lotto_pred/core/storage/session_storage.dart';

/// Centralized API configuration supporting local development and remote cloud deployments (e.g. Render).
class ApiConstants {
  ApiConstants._();

  static const String _envBackendUrl = String.fromEnvironment('BACKEND_URL');
  static const String _storageKey = 'llis_backend_api_url';

  /// Resolves the active backend base URL
  static String get baseUrl {
    // 1. Check user-configured override in storage
    final customUrl = WebSessionStorage.getItem(_storageKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    // 2. Check --dart-define=BACKEND_URL=...
    if (_envBackendUrl.isNotEmpty) {
      return _envBackendUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    // 3. Web runtime host detection
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1' && host != '0.0.0.0') {
        // When hosted on GitHub Pages or custom domain, default to Render cloud deployment
        return 'https://llis-backend.onrender.com';
      }
    }

    return 'http://localhost:8081';
  }

  /// Sets a custom backend base URL (e.g., https://my-render-app.onrender.com)
  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      WebSessionStorage.removeItem(_storageKey);
    } else {
      WebSessionStorage.setItem(_storageKey, url.trim().replaceAll(RegExp(r'/+$'), ''));
    }
  }

  // Common API Endpoints
  static String get syncEndpoint => '$baseUrl/api/pcso-results';
  static String get triggerSyncEndpoint => '$baseUrl/api/sync/trigger';
  static String get importEndpoint => '$baseUrl/api/pcso-results/import';
  static String get clearEndpoint => '$baseUrl/api/sync/clear';
  static String get logsEndpoint => '$baseUrl/api/sync/logs';
  static String get autoScrapeConfigEndpoint => '$baseUrl/api/sync/auto-scrape-config';
  static String get autoScrapeTriggerNowEndpoint => '$baseUrl/api/sync/auto-scrape-trigger-now';
  static String get usersEndpoint => '$baseUrl/api/users';
  static String get userSyncEndpoint => '$baseUrl/api/users/sync';
  static String get picksEndpoint => '$baseUrl/api/picks';
  static String get picksSyncEndpoint => '$baseUrl/api/picks/sync';
  static String get healthEndpoint => '$baseUrl/api/health';
}
