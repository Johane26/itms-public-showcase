import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class OwnerAuthService extends ChangeNotifier {
  OwnerAuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  bool get isAuthenticated => _token != null;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/owner/login'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode != 200) return false;

      final payload = json.decode(response.body);
      if (payload is! Map<String, dynamic> ||
          payload['token'] is! String ||
          (payload['token'] as String).isEmpty) {
        return false;
      }
      _token = payload['token'] as String;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> get(Uri uri) {
    final token = _token;
    if (token == null) {
      throw StateError('Owner sign in is required for this request.');
    }
    return _client.get(uri, headers: {'Authorization': 'Bearer $token'});
  }

  void logout() {
    _token = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
