import 'dart:typed_data';

import 'api_client.dart';

class UploadService {
  final ApiClient _api;

  UploadService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// Upload bytes của một ảnh lên Cloudinary qua backend.
  /// Trả về URL công khai (secure_url).
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final envelope = await _api.uploadBytes('/upload/image', bytes, filename);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) throw Exception('Server không trả về URL ảnh');
    return url;
  }

  /// Upload bytes của một video lên Cloudinary qua backend.
  /// Trả về URL công khai (secure_url).
  Future<String> uploadVideo(Uint8List bytes, String filename) async {
    final envelope = await _api.uploadBytes('/upload/video', bytes, filename);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) throw Exception('Server không trả về URL video');
    return url;
  }
}
