import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'supabase_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  ApiException({required this.statusCode, required this.code, required this.message});

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Thin REST client for the Mintro Node API (see services/api). Automatically
/// attaches the current Supabase session's access token as a Bearer token.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SupabaseService.accessToken != null)
          'Authorization': 'Bearer ${SupabaseService.accessToken}',
      };

  dynamic _unwrap(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    final error = (body as Map<String, dynamic>)['error'] as Map<String, dynamic>?;
    throw ApiException(
      statusCode: response.statusCode,
      code: error?['code'] as String? ?? 'UNKNOWN',
      message: error?['message'] as String? ?? 'Request failed',
    );
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers);
    return _unwrap(response);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );
    return _unwrap(response);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );
    return _unwrap(response);
  }
}
