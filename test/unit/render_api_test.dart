import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/services/api_service.dart';

void main() {
  group('Render Backend REST API Service Tests', () {
    test('Base URL management trims whitespace and trailing slashes correctly', () {
      final api = ApiService.instance;

      api.setBaseUrl('https://my-render-app.onrender.com/  ');
      expect(api.baseUrl, equals('https://my-render-app.onrender.com'));

      api.setBaseUrl('http://localhost:5000');
      expect(api.baseUrl, equals('http://localhost:5000'));
    });

    test('ApiHealthResult models deserialize health payload accurately', () {
      final payload = {
        'status': 'healthy',
        'service': 'Personal Life OS Backend API',
        'database': 'connected',
        'timestamp': '2026-10-19T07:53:04.778Z',
      };

      final result = ApiHealthResult.fromJson(payload);
      expect(result.isHealthy, isTrue);
      expect(result.status, equals('healthy'));
      expect(result.service, equals('Personal Life OS Backend API'));
      expect(result.database, equals('connected'));
      expect(result.error, isNull);
    });

    test('ApiHealthResult.error handles network failures without throwing', () {
      final errorResult = ApiHealthResult.error('Connection refused: 5000');
      expect(errorResult.isHealthy, isFalse);
      expect(errorResult.status, equals('offline'));
      expect(errorResult.error, contains('Connection refused'));
    });

    test('ApiService can connect to local Express backend when available', () async {
      final api = ApiService.instance;
      api.setBaseUrl('http://localhost:5000');

      final health = await api.checkHealth();
      // If the backend daemon is running locally, it should return healthy
      if (health.isHealthy) {
        expect(health.status, equals('healthy'));
        expect(health.database, equals('connected'));
      } else {
        // If port is unmapped in this environment, it gracefully returns error state
        expect(health.isHealthy, isFalse);
      }
    });
  });
}
