import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class Api {
  String? token;

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final uri = Uri.parse('${Config.apiBase}$path')
        .replace(queryParameters: (query == null || query.isEmpty) ? null : query);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response r;
    try {
      final f = switch (method) {
        'POST' => http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };
      r = await f.timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your internet connection and try again.');
    }
    dynamic data;
    try {
      data = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body);
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (r.statusCode >= 400) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Something went wrong (${r.statusCode})';
      throw ApiException(msg, r.statusCode);
    }
    return data;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, Map<String, dynamic> body) => _send('POST', path, body: body);
  Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);
}
