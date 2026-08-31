import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// The Android emulator can't reach the host machine via `localhost` — it
/// maps the host loopback to 10.0.2.2 instead. Every other target we run on
/// during development (Windows desktop, Chrome, iOS simulator) uses
/// `localhost` directly.
String _defaultBaseUrl() {
  if (kIsWeb) return 'http://localhost:4000';
  if (Platform.isAndroid) return 'http://10.0.2.2:4000';
  return 'http://localhost:4000';
}

class ApiException implements Exception {
  final int statusCode;
  final String error;
  ApiException(this.statusCode, this.error);
  @override
  String toString() => 'ApiException($statusCode, $error)';
}

class ApiClient {
  final String baseUrl;
  String? parentToken;
  String? deviceToken;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  Map<String, String> _headers({bool asParent = false, bool asChild = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (asParent && parentToken != null) headers['Authorization'] = 'Bearer $parentToken';
    if (asChild && deviceToken != null) headers['X-Device-Token'] = deviceToken!;
    return headers;
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, body['error'] ?? 'unknown_error');
    }
    return body;
  }

  Future<dynamic> get(String path, {bool asParent = false, bool asChild = false}) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers(asParent: asParent, asChild: asChild));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool asParent = false, bool asChild = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(asParent: asParent, asChild: asChild),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }
}
