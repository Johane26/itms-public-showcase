import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:passenger_app/services/api_service.dart';

void main() {
  test(
    'protected passenger data requests include the supplied bearer token',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('[]', 200);
      });
      final api = ApiService(
        token: 'test-jwt',
        client: client,
        baseUrl: 'https://api.example.test',
      );
      addTearDown(client.close);

      await api.fetchAllDrivers();
      await api.fetchActiveDrivers();

      expect(requests.map((request) => request.url.path), [
        '/api/drivers',
        '/api/locations/active',
      ]);
      expect(
        requests.map((request) => request.headers['Authorization']),
        everyElement('Bearer test-jwt'),
      );
    },
  );
}
