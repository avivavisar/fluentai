import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_client.dart';
import 'config.dart';

/// Thin HTTP client for the FluentAI API. Attaches the Supabase access token
/// (verified by the backend) as a Bearer header on every request.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Map<String, String> _headers() {
    final token = AuthClient.instance.client.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<dynamic> get(String path) async {
    final res = await _client.get(_uri(path), headers: _headers());
    return _parse(res);
  }

  Future<dynamic> post(String path, [Object? body]) async {
    final res = await _client.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _parse(res);
  }

  Future<dynamic> patch(String path, [Object? body]) async {
    final res = await _client.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final data = res.body.isEmpty ? null : jsonDecode(res.body);
    if (!ok) {
      final msg = (data is Map && data['message'] != null) ? data['message'].toString() : 'Request failed';
      throw ApiException(res.statusCode, msg);
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}
