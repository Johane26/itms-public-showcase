import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/driver.dart';

class ApiService {
  ApiService({required this.token, http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'Must not be empty.');
    }
  }

  final String token;
  final http.Client _client;
  final String _baseUrl;

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $token'};

  // Fetch all drivers (to get routes and basic info)
  Future<List<Driver>> fetchAllDrivers() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/drivers'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Driver.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // Fetch active drivers with their latest GPS location
  Future<List<Driver>> fetchActiveDrivers() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/locations/active'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map(
              (json) => Driver(
                id: json['driverId'] ?? 0,
                fullName: json['fullName'] ?? 'Unknown',
                phoneNumber: '',
                vehicleRegistration: json['vehicleRegistration'] ?? 'N/A',
                route: 'N/A',
                status: 'ON_TRIP',
                latitude: json['latitude']?.toDouble(),
                longitude: json['longitude']?.toDouble(),
              ),
            )
            .toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
}
