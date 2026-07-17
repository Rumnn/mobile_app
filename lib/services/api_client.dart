import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'app_config.dart';
import 'token_storage.dart';

/// Determine the MediaType from a filename extension.
MediaType _mediaTypeOf(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  const types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
  };
  final mime = types[ext] ?? 'application/octet-stream';
  final parts = mime.split('/');
  return MediaType(parts[0], parts[1]);
}

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

  /// Upload raw bytes via multipart/form-data.
  /// Works on Flutter Web AND mobile (no dart:io File needed).
  Future<Map<String, dynamic>> uploadBytes(
    String apiPath,
    Uint8List bytes,
    String filename, {
    String field = 'file',
  }) async {
    final token = await _tokenStorage.getToken();
    final request = http.MultipartRequest('POST', _uri(apiPath));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: _mediaTypeOf(filename),
    ));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final envelope = _decodeBody(body);
    _ensureSuccessEnvelope(envelope, streamed.statusCode);
    return envelope;
  }
}

