import 'dart:convert';

import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

const String defaultApiBaseUrl = String.fromEnvironment(
  'ETLINGO_API_URL',
  defaultValue: 'http://localhost:5050/api/v1',
);

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => statusCode >= 500
      ? 'Server error ($statusCode). Please try again later.'
      : message;
}

/// Thin JSON API client that attaches the stored JWT to every request.
class ApiClient {
  ApiClient({required this.tokenProvider, String? baseUrl})
      : baseUrl = baseUrl ?? defaultApiBaseUrl;

  final TokenProvider tokenProvider;
  final String baseUrl;

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  Future<http.Response> _send(
    Future<http.Response> Function(Uri, Map<String, String>) fn,
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final token = auth ? await tokenProvider() : null;
    if (auth && (token == null || token.isEmpty)) {
      throw ApiException(401, 'Not signed in');
    }
    final uri = Uri.parse('$baseUrl$path');
    final response = await fn(uri, _headers(token: token));
    return response;
  }

  dynamic _decode(http.Response response) {
    final raw = response.body;
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final data = raw.isEmpty ? null : jsonDecode(raw);
        if (data is Map && data['error'] is String) message = data['error'] as String;
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();
    // Some proxies / empty handlers return the literal text "null".
    if (trimmed == 'null' || trimmed == 'undefined') return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      throw ApiException(response.statusCode, 'Invalid server response');
    }
  }

  static String describeError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) {
        return 'Please sign in to like or comment.';
      }
      return e.message;
    }
    return 'Network error — check that the backend is running.';
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final r = await _send((uri, h) => http.get(uri, headers: h), path, auth: auth);
    return _decode(r);
  }

  /// GET that attaches a JWT **when available** (public + likedByMe).
  Future<dynamic> getWithOptionalAuth(String path) async {
    final token = await tokenProvider();
    final hasToken = token != null && token.isNotEmpty;
    final r = await _send(
      (uri, h) => http.get(uri, headers: h),
      path,
      auth: hasToken,
    );
    return _decode(r);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    // Express 5 rejects a top-level JSON null — send an empty object instead.
    final payload = body == null ? '{}' : jsonEncode(body);
    final r = await _send(
      (uri, h) => http.post(uri, headers: h, body: payload),
      path,
      body: body,
      auth: auth,
    );
    return _decode(r);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final r = await _send(
      (uri, h) => http.put(uri, headers: h, body: jsonEncode(body)),
      path,
      body: body,
      auth: auth,
    );
    return _decode(r);
  }

  Future<void> delete(String path) async {
    final r = await _send((uri, h) => http.delete(uri, headers: h), path);
    if (r.statusCode >= 400) _decode(r);
  }
}