import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:owner_dashboard/services/owner_auth_service.dart';

void main() {
  test('owner token is sent to protected API requests', () async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/api/auth/owner/login');
        expect(json.decode(request.body), {
          'email': 'owner@example.test',
          'password': 'test-password',
        });
        return http.Response(json.encode({'token': 'test-jwt'}), 200);
      }

      expect(request.method, 'GET');
      expect(request.url.path, '/api/dashboard/stats');
      expect(request.headers['Authorization'], 'Bearer test-jwt');
      return http.Response('{}', 200);
    });
    final authService = OwnerAuthService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(authService.dispose);

    expect(authService.isAuthenticated, isFalse);
    expect(
      await authService.login('owner@example.test', 'test-password'),
      isTrue,
    );
    expect(authService.isAuthenticated, isTrue);

    final response = await authService.get(
      Uri.parse('https://api.example.test/api/dashboard/stats'),
    );
    expect(response.statusCode, 200);
  });

  test('failed login does not authenticate the owner', () async {
    final client = MockClient((_) async => http.Response('Unauthorized', 401));
    final authService = OwnerAuthService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(authService.dispose);

    expect(
      await authService.login('owner@example.test', 'bad-password'),
      isFalse,
    );
    expect(authService.isAuthenticated, isFalse);
  });

  test('protected request is rejected locally before sign in', () {
    final client = MockClient(
      (_) async => throw StateError('Unauthenticated request must not be sent'),
    );
    final authService = OwnerAuthService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(authService.dispose);

    expect(
      () => authService.get(
        Uri.parse('https://api.example.test/api/dashboard/stats'),
      ),
      throwsStateError,
    );
  });
}
