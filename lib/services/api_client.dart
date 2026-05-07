import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final TokenStorage _tokenStorage;
  final http.Client _http;

  ApiClient({
    TokenStorage? tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _http = httpClient ?? http.Client();

  Uri _uri(String path) {
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Future<Map<String, String>> _headers({bool authorized = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authorized) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decodeBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Invalid response format');
  }

  void _ensureSuccessEnvelope(Map<String, dynamic> envelope, int statusCode) {
    final success = envelope['success'];
    if (success == true) return;
    final message = (envelope['message'] ?? 'Request failed').toString();
    throw ApiException(message, statusCode: statusCode);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _http.get(_uri(path), headers: await _headers());
    final envelope = _decodeBody(res.body);
    _ensureSuccessEnvelope(envelope, res.statusCode);
    return envelope;
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, bool authorized = true}) async {
    final res = await _http.post(
      _uri(path),
      headers: await _headers(authorized: authorized),
      body: jsonEncode(body ?? const {}),
    );
    final envelope = _decodeBody(res.body);
    _ensureSuccessEnvelope(envelope, res.statusCode);
    return envelope;
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final res = await _http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? const {}),
    );
    final envelope = _decodeBody(res.body);
    _ensureSuccessEnvelope(envelope, res.statusCode);
    return envelope;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _http.delete(_uri(path), headers: await _headers());
    final envelope = _decodeBody(res.body);
    _ensureSuccessEnvelope(envelope, res.statusCode);
    return envelope;
  }
}

