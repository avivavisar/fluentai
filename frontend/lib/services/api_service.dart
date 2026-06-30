import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final StorageService _storage;
  ApiService(this._storage);

  Uri _uri(String path) {
    const base = AppConfig.apiBaseUrl;
    // Empty base => same-origin (relative to the page that served the app).
    if (base.isEmpty) return Uri.base.resolve(path);
    return Uri.parse('$base$path');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.readToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(_uri(path), headers: await _headers(auth: auth));
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.patch(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _handle(res);
  }

  // POST returning raw bytes (e.g. TTS audio).
  Future<Uint8List> postForBytes(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await http.post(_uri(path),
        headers: await _headers(auth: auth), body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    throw ApiException(res.statusCode, 'Request failed');
  }

  dynamic _handle(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map && body['error'] is Map)
        ? body['error']['message']
        : 'Request failed';
    throw ApiException(res.statusCode, msg?.toString() ?? 'Request failed');
  }
}
