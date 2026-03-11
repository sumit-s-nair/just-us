import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// REST API client with automatic JWT refresh and request logging.
class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  // ── Token Management ──────────────────────────────────────────────

  Future<String?> get accessToken => _storage.read(key: 'access_token');
  Future<String?> get refreshToken => _storage.read(key: 'refresh_token');

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> get hasTokens async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  // ── Logging ───────────────────────────────────────────────────────

  void _logError(String method, String path, Object error, int ms) {
    debugPrint('[API] ✗ $method $path → ERROR: $error (${ms}ms)');
  }

  void _logResponse(String method, String path, int statusCode, int ms) {
    // Suppress the error log for 401s on the logout endpoint since we explicitly
    // skip token refresh for it. It's expected if the token naturally expired.
    if (statusCode == 401 && path.endsWith('/api/auth/logout')) {
      debugPrint('[API] - $method $path → 401 (ignored during logout) (${ms}ms)');
      return;
    }
    
    final emoji = statusCode >= 200 && statusCode < 300 ? '✓' : '✗';
    debugPrint('[API] $emoji $method $path → $statusCode (${ms}ms)');
  }

  // ── HTTP Methods ──────────────────────────────────────────────────

  static const _timeout = Duration(seconds: 10);

  Future<Map<String, String>> _authHeaders() async {
    final token = await accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final sw = Stopwatch()..start();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(),
      ).timeout(_timeout);
      _logResponse('GET', path, response.statusCode, sw.elapsedMilliseconds);
      return _handleResponse(response, path, () => get(path));
    } catch (e) {
      _logError('GET', path, e, sw.elapsedMilliseconds);
      rethrow;
    }
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final sw = Stopwatch()..start();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      _logResponse('POST', path, response.statusCode, sw.elapsedMilliseconds);
      return _handleResponse(response, path, () => post(path, body: body));
    } catch (e) {
      _logError('POST', path, e, sw.elapsedMilliseconds);
      rethrow;
    }
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final sw = Stopwatch()..start();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      _logResponse('PUT', path, response.statusCode, sw.elapsedMilliseconds);
      return _handleResponse(response, path, () => put(path, body: body));
    } catch (e) {
      _logError('PUT', path, e, sw.elapsedMilliseconds);
      rethrow;
    }
  }

  Future<http.Response> delete(String path) async {
    final sw = Stopwatch()..start();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(),
      ).timeout(_timeout);
      _logResponse('DELETE', path, response.statusCode, sw.elapsedMilliseconds);
      return _handleResponse(response, path, () => delete(path));
    } catch (e) {
      _logError('DELETE', path, e, sw.elapsedMilliseconds);
      rethrow;
    }
  }

  // ── Auto-Refresh ──────────────────────────────────────────────────

  Future<http.Response> _handleResponse(
    http.Response response,
    String path,
    Future<http.Response> Function() retry,
  ) async {
    // If we get a 401, aren't already refreshing, and this ISN'T the logout endpoint
    // (no point refreshing a token just to log out).
    if (response.statusCode == 401 &&
        !_isRefreshing &&
        !path.endsWith('/api/auth/logout')) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return retry();
      }
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    debugPrint('[API] ↻ Refreshing access token…');
    final sw = Stopwatch()..start();
    try {
      final token = await refreshToken;
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': token}),
      ).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(
          key: 'access_token',
          value: data['accessToken'] as String,
        );
        debugPrint('[API] ↻ Token refreshed (${sw.elapsedMilliseconds}ms)');
        return true;
      }

      debugPrint('[API] ↻ Refresh failed: ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
      if (response.statusCode == 401 || response.statusCode == 403) {
         await clearTokens();
      }
      return false;
    } catch (e) {
      debugPrint('[API] ↻ Refresh error: $e (${sw.elapsedMilliseconds}ms)');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
