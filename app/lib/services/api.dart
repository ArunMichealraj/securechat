import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => message;
}

class Api {
  Api(this.baseUrl, {this.token});

  final String baseUrl;
  final String? token;

  /// "192.168.0.5:3000/" -> "http://192.168.0.5:3000"
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await request.send().timeout(const Duration(seconds: 15)));
    } catch (_) {
      throw ApiException(0, 'Cannot reach server at $baseUrl. Check the address and that the phone is on the same Wi-Fi.');
    }

    final json = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = json is Map ? json['message'] : null;
      throw ApiException(
        response.statusCode,
        message is List ? message.join('\n') : (message?.toString() ?? 'Request failed (${response.statusCode})'),
      );
    }
    return json;
  }
}
