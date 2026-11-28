import 'package:fikra/data/product/api/api_auth.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/account/google_identity.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_integration_test.dart' show ScriptTransport, client, jsonReply, pair, user;

class FakeGoogle implements GoogleIdentity {
  FakeGoogle(this.credential);
  final GoogleCredential? credential;
  int calls = 0;
  @override
  bool get available => true;
  @override
  Future<GoogleCredential?> authenticate() async {
    calls++;
    return credential;
  }
}

void main() {
  test('native identity is exchanged for FIKRAH tokens and authoritative account', () async {
    final transport = ScriptTransport((c) => jsonReply(c.uri.path.endsWith('/me') ? user : pair('new')));
    final vault = MemorySessionVault();
    final session = SessionController(ApiAuthRepository(client(transport)), vault);
    addTearDown(session.dispose);
    await session.googleWith(FakeGoogle(const GoogleCredential('test-google-id-token', name: ' Alice ')));
    expect(transport.calls.first.json, {'id_token': 'test-google-id-token', 'name': 'Alice'});
    expect(transport.calls[1].headers['Authorization'], 'Bearer access-new');
    expect(session.stage, SessionStage.authenticated);
    expect(vault.value!.refresh, 'refresh-new');
    expect(session.googleActive, isFalse);
  });
  test('canceling account picker never contacts backend or modifies vault', () async {
    final transport = ScriptTransport((_) => jsonReply(pair('new')));
    final vault = MemorySessionVault();
    final session = SessionController(ApiAuthRepository(client(transport)), vault);
    addTearDown(session.dispose);
    await session.googleWith(FakeGoogle(null));
    expect(transport.calls, isEmpty);
    expect(vault.value, isNull);
    expect(session.stage, SessionStage.restoring);
    expect(session.failure, isNull);
  });
  test('server missing-name response asks for name then retries the same identity once', () async {
    final transport = ScriptTransport((c) {
      if (c.uri.path.endsWith('/me')) return jsonReply(user);
      if ((c.json as Map)['name'] == null) {
        return jsonReply({'detail': 'Name is required to create an account'}, status: 422);
      }
      return jsonReply(pair('new'));
    });
    final session = SessionController(ApiAuthRepository(client(transport)), MemorySessionVault());
    addTearDown(session.dispose);
    await session.googleWith(FakeGoogle(const GoogleCredential('test-google-id-token')));
    expect(session.needsGoogleName, isTrue);
    expect(session.failure, isNull);
    await session.completeGoogleName(' محمد ');
    expect(transport.calls[1].json, {'id_token': 'test-google-id-token', 'name': 'محمد'});
    expect(session.stage, SessionStage.authenticated);
    expect(session.needsGoogleName, isFalse);
  });
  test('invalid Google token is mapped without leaking provider details', () async {
    final session = SessionController(
      ApiAuthRepository(client(ScriptTransport((_) => jsonReply({'detail': 'private'}, status: 401)))),
      MemorySessionVault(),
    );
    addTearDown(session.dispose);
    await session.googleWith(FakeGoogle(const GoogleCredential('test-google-id-token')));
    expect(session.failure!.kind, FailureKind.unauthorized);
    expect(session.failure!.field, 'google');
    expect(session.needsGoogleName, isFalse);
  });
}
