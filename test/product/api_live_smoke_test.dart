import 'dart:io';

import 'package:fikra/app/app_config.dart' show apiOrigin;
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/models.dart';
import 'package:flutter_test/flutter_test.dart';

// Explicit opt-in: public read-only calls, no credentials, mail or AI charges.
void main() {
  test(
    'live HTTPS origin exposes ready services, OTP schema and protected account route',
    () async {
      final api = ApiClient(Uri.parse(apiOrigin));
      final health = await api.request('GET', '/health');
      expect(health['status'], 'ok');
      final ready = await api.request('GET', '/ready');
      expect(ready['status'], 'ready');
      final schema = await api.request('GET', '/openapi.json');
      expect(schema['paths'].containsKey('/v1/auth/verify-email/otp'), isTrue);
      expect(schema['components']['schemas']['EmailOtpRequest']['properties']['code']['minLength'], 6);
      expect(schema['components']['schemas']['Credentials']['properties']['password']['minLength'], 5);
      await expectLater(
        api.request('GET', '/v1/auth/me'),
        throwsA(isA<ProductFailure>().having((f) => f.kind, 'kind', FailureKind.unauthorized)),
      );
    },
    skip: Platform.environment['FIKRA_LIVE_SMOKE'] != '1',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
