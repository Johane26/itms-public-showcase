import 'package:flutter_test/flutter_test.dart';
import 'package:owner_dashboard/config/api_config.dart';

void main() {
  group('API_BASE_URL policy', () {
    test('allows local HTTP in debug builds', () {
      expect(
        ApiConfig.validateBaseUrl('http://localhost:8080/', isRelease: false),
        'http://localhost:8080',
      );
      expect(
        ApiConfig.validateBaseUrl(
          'http://127.255.255.254:8080',
          isRelease: false,
        ),
        'http://127.255.255.254:8080',
      );
      expect(
        ApiConfig.validateBaseUrl('http://[::1]:8080', isRelease: false),
        'http://[::1]:8080',
      );
    });

    test('rejects missing and malformed values', () {
      expect(
        () => ApiConfig.validateBaseUrl('', isRelease: false),
        throwsA(isA<StateError>()),
      );
      expect(
        () => ApiConfig.validateBaseUrl('not a URL', isRelease: false),
        throwsA(isA<FormatException>()),
      );
    });

    test('release builds require HTTPS', () {
      expect(
        () => ApiConfig.validateBaseUrl(
          'http://api.example.test',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        ApiConfig.validateBaseUrl('https://api.example.test', isRelease: true),
        'https://api.example.test',
      );
    });

    test('release builds reject IPv4 loopback throughout 127/8', () {
      for (final host in ['127.0.0.1', '127.0.0.2', '127.255.255.254']) {
        expect(
          () => ApiConfig.validateBaseUrl('https://$host', isRelease: true),
          throwsA(isA<StateError>()),
          reason: '$host must be treated as IPv4 loopback',
        );
      }
    });

    test('release builds reject IPv6 and IPv4-mapped IPv6 loopback', () {
      for (final host in [
        'localhost',
        'localhost.',
        '[::1]',
        '[::ffff:127.0.0.1]',
        '[::ffff:7f00:1]',
        '[::ffff:7fff:fffe]',
      ]) {
        expect(
          () => ApiConfig.validateBaseUrl('https://$host', isRelease: true),
          throwsA(isA<StateError>()),
          reason: '$host must be treated as loopback',
        );
      }
    });
  });
}
