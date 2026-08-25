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
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] is String) message = data['error'] as String;
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final r = await _send((uri, h) => http.get(uri, headers: h), path, auth: auth);
    return _decode(r);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final r = await _send(
      (uri, h) => http.post(uri, headers: h, body: jsonEncode(body)),
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