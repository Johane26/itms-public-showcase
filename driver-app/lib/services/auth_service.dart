import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String get baseUrl => ApiConfig.baseUrl;
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<Map<String, dynamic>?> loginDriver(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/driver/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('token')) {
          _token = data['token'];
          _user = data;
          return data;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  void logout() {
    _token = null;
    _user = null;
  }

  Map<String, String> getAuthHeaders() {
    // Return headers with token if available, otherwise just content type
    if (_token == null) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
}
