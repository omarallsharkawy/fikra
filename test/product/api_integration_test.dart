import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fikra/data/product/api/api_auth.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/api/api_knowledge.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/secure_attempt_store.dart';
import 'package:fikra/data/product/secure_session_vault.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const user = {'id': 'user-a', 'email': 'test@example.invalid', 'email_verified': true};
const project = {'id': 'project-a', 'name': 'General', 'is_general': true, 'created_at': '2026-11-27T00:00:00Z'};
const note = {
  'id': 'note-a',
  'project_id': 'project-a',
  'title': null,
  'content': 'A thought',
  'concepts': ['idea'],
  'refinement_proposal': null,
  'revision': 1,
  'processing_generation': 2,
  'processing_status': 'queued',
  'created_at': '2026-11-27T00:00:00Z',
  'updated_at': '2026-11-27T00:00:00Z',
  'is_favorite': true,
};
const conversation = {
  'id': 'conversation-a',
  'project_id': 'project-a',
  'title': null,
  'created_at': '2026-11-27T00:00:00Z',
  'updated_at': '2026-11-27T00:00:00Z',
};
const message = {
  'id': 'message-a',
  'role': 'assistant',
  'content': 'Final answer',
  'supported': true,
  'sources': [
    {'note_id': 'note-a', 'title': null},
  ],
  'created_at': '2026-11-27T00:00:00Z',
};
Map<String, Object> pair(String suffix) => {
  'access_token': 'access-$suffix',
  'refresh_token': 'refresh-$suffix',
  'expires_in': 900,
};

class Call {
  Call(this.method, this.uri, this.headers, this.bytes);
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final List<int> bytes;
  dynamic get json => bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
}

class ScriptTransport implements ApiTransport {
  ScriptTransport(this.reply);
  final FutureOr<ApiResponse> Function(Call) reply;
  final calls = <Call>[];
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    Map<String, String> headers,
    ApiBody? body,
    ApiCancellation cancel,
  ) async {
    final call = Call(method, uri, {
      ...headers,
      if (body != null) 'Content-Type': body.type,
    }, body == null ? [] : await body.open().expand((v) => v).toList());
    calls.add(call);
    return reply(call);
  }
}

ApiResponse jsonReply(dynamic body, {int status = 200, Map<String, String> headers = const {}}) => ApiResponse(
  status,
  {'content-type': 'application/json', ...headers},
  Stream.value(utf8.encode(jsonEncode(body))),
  () {},
);
ApiClient client(ScriptTransport t, {Duration timeout = const Duration(seconds: 180)}) =>
    ApiClient(Uri.parse('https://api.example.invalid'), transport: t, timeout: timeout);
SessionController signedIn(ApiClient api, {MemorySessionVault? vault}) {
  final s = SessionController(ApiAuthRepository(api), vault ?? MemorySessionVault());
  s.stage = SessionStage.authenticated;
  s.account = const Account(id: 'user-a', email: 'test@example.invalid', emailVerified: true);
  s.tokens = TokenPair(access: 'access-old', refresh: 'refresh-old', expiresAt: DateTime(2030));
  api.session = s;
  addTearDown(s.dispose);
  return s;
}

Matcher kind(FailureKind k) => isA<ProductFailure>().having((e) => e.kind, 'kind', k);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('API config requires an HTTPS origin and rejects embedded credentials or path', () {
    for (final url in [
      'http://api.example',
      'https://secret@api.example',
      'https://api.example/v1',
      'https://api.example?x=1',
    ]) {
      expect(() => ApiClient(Uri.parse(url)), throwsArgumentError);
    }
  });
  test('OTP registration/verification/recovery send exact fields without bearer or action links', () async {
    final t = ScriptTransport((_) => jsonReply({'message': 'accepted'}, status: 202)),
        api = client(t),
        auth = ApiAuthRepository(api);
    await auth.register('test@example.invalid', 'abcde');
    await auth.verifyEmail('123456', email: 'test@example.invalid');
    await auth.resendVerification('test@example.invalid');
    await auth.requestRecovery('test@example.invalid');
    await auth.confirmRecovery('654321', 'new password', email: 'test@example.invalid');
    expect(t.calls.map((c) => c.uri.path), [
      '/v1/auth/register/otp',
      '/v1/auth/verify-email/otp',
      '/v1/auth/resend-verification/otp',
      '/v1/auth/password-reset/otp/request',
      '/v1/auth/password-reset/otp/confirm',
    ]);
    expect(t.calls[1].json, {'email': 'test@example.invalid', 'code': '123456'});
    expect(t.calls.last.json, {'email': 'test@example.invalid', 'code': '654321', 'new_password': 'new password'});
    expect(t.calls.every((c) => !c.headers.containsKey('Authorization')), isTrue);
    final invalid = ApiAuthRepository(client(ScriptTransport((_) => jsonReply({'detail': 'expired'}, status: 400))));
    await expectLater(
      invalid.verifyEmail('123456', email: 'test@example.invalid'),
      throwsA(isA<ProductFailure>().having((f) => f.field, 'field', 'code')),
    );
  });
  test('login and Google fetch server account with issued bearer; logout uses refresh token', () async {
    final t = ScriptTransport((c) => jsonReply(c.uri.path.endsWith('/me') ? user : pair('new'))),
        auth = ApiAuthRepository(client(t));
    final login = await auth.login('test@example.invalid', '  untrimmed  ');
    expect(t.calls.first.json, {'email': 'test@example.invalid', 'password': '  untrimmed  '});
    expect(t.calls[1].headers['Authorization'], 'Bearer access-new');
    expect(login.account.id, 'user-a');
    expect(login.tokens!.refresh, 'refresh-new');
    await auth.exchangeGoogleIdToken('google-token');
    expect(t.calls[2].json, {'id_token': 'google-token'});
    expect(await auth.logout(login.tokens), isTrue);
    expect(t.calls.last.json, {'refresh_token': 'refresh-new'});
  });
  test('restored valid session reads me; expired session rotates once and stores replacement', () async {
    final vault = MemorySessionVault();
    await vault.replace(TokenPair(access: 'access-old', refresh: 'refresh-old', expiresAt: DateTime(2000)));
    final t = ScriptTransport((c) {
          if (c.uri.path.endsWith('/refresh')) {
            expect(vault.value, isNull);
            return jsonReply(pair('new'));
          }
          return jsonReply(user);
        }),
        api = client(t),
        s = SessionController(ApiAuthRepository(api), vault);
    api.session = s;
    addTearDown(s.dispose);
    await s.restore();
    expect(s.stage, SessionStage.authenticated);
    expect(vault.value!.refresh, 'refresh-new');
    expect(t.calls.map((c) => c.uri.path), ['/v1/auth/refresh', '/v1/auth/me']);
    final again = SessionController(ApiAuthRepository(api), vault);
    api.session = again;
    addTearDown(again.dispose);
    await again.restore();
    expect(again.stage, SessionStage.authenticated);
    expect(t.calls.last.uri.path, '/v1/auth/me');
    expect(t.calls.length, 3);
  });
  test('session login normalizes only email and preserves password case, Unicode and whitespace', () async {
    const password = '  CaseSensitive-é-فكرة-42  ';
    final transport = ScriptTransport(
      (call) => call.uri.path.endsWith('/me') ? jsonReply(user) : jsonReply(pair('new')),
    );
    final api = client(transport);
    final session = SessionController(ApiAuthRepository(api), MemorySessionVault());
    addTearDown(session.dispose);
    await session.login('  Test@EXAMPLE.com  ', password);
    expect(session.stage, SessionStage.authenticated);
    expect(transport.calls.first.uri.path, '/v1/auth/login');
    expect(transport.calls.first.json, {'email': 'test@example.com', 'password': password});
    expect(transport.calls.first.headers.containsKey('Authorization'), isFalse);
  });

  test('parallel protected 401s share one refresh, persist pair before retry, and retry only once', () async {
    final refresh = Completer<ApiResponse>(), vault = MemorySessionVault();
    final t = ScriptTransport((c) {
          if (c.uri.path.endsWith('/refresh')) return refresh.future;
          if (c.headers['Authorization'] == 'Bearer access-old') return jsonReply({}, status: 401);
          expect(vault.value!.access, 'access-new');
          return jsonReply([project]);
        }),
        api = client(t);
    final s = signedIn(api, vault: vault);
    await vault.replace(s.tokens!);
    final repo = ApiKnowledgeRepository(api);
    final a = repo.projects('user-a'), b = repo.projects('user-a');
    while (!t.calls.any((c) => c.uri.path.endsWith('/refresh'))) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(vault.value, isNull);
    refresh.complete(jsonReply(pair('new')));
    expect((await a).single.isGeneral, isTrue);
    await b;
    expect(t.calls.where((c) => c.uri.path.endsWith('/refresh')).length, 1);
    expect(s.tokens!.refresh, 'refresh-new');
  });
  test('repeated resource 401 stops after one refresh; uncertain refresh expires and cannot replay', () async {
    final t = ScriptTransport(
          (c) => c.uri.path.endsWith('/refresh') ? jsonReply(pair('new')) : jsonReply({}, status: 401),
        ),
        api = client(t);
    signedIn(api);
    await expectLater(ApiKnowledgeRepository(api).projects('user-a'), throwsA(kind(FailureKind.unauthorized)));
    expect(t.calls.length, 3);
    final bad = ScriptTransport((c) {
      if (c.uri.path.endsWith('/refresh')) throw const SocketException('lost');
      return jsonReply({}, status: 401);
    });
    final next = client(bad), s = signedIn(next);
    await expectLater(ApiKnowledgeRepository(next).projects('user-a'), throwsA(kind(FailureKind.uncertain)));
    expect(s.stage, SessionStage.expired);
    expect(await s.vault.read(), isNull);
    await expectLater(ApiKnowledgeRepository(next).projects('user-a'), throwsA(kind(FailureKind.unauthorized)));
    expect(bad.calls.length, 2);
  });
  test('account mismatch and late response after logout never return private data', () async {
    final delayed = Completer<ApiResponse>(), t = ScriptTransport((_) => delayed.future), api = client(t);
    final s = signedIn(api);
    await expectLater(ApiKnowledgeRepository(api).projects('other-user'), throwsA(kind(FailureKind.unauthorized)));
    expect(t.calls, isEmpty);
    final pending = ApiKnowledgeRepository(api).projects('user-a');
    await Future<void>.delayed(Duration.zero);
    await s.expire();
    delayed.complete(jsonReply([project]));
    await expectLater(pending, throwsA(kind(FailureKind.unauthorized)));
  });
  test('restore retries a cached rejected access token once; revoked family clears storage', () async {
    final vault = MemorySessionVault();
    await vault.replace(TokenPair(access: 'cached', refresh: 'old-refresh', expiresAt: DateTime(2030)));
    var reads = 0;
    final t = ScriptTransport((c) {
          if (c.uri.path.endsWith('/refresh')) return jsonReply(pair('rotated'));
          reads++;
          return jsonReply({}, status: 401);
        }),
        api = client(t),
        session = SessionController(ApiAuthRepository(api), vault);
    api.session = session;
    addTearDown(session.dispose);
    await session.restore();
    expect(session.stage, SessionStage.expired);
    expect(await vault.read(), isNull);
    expect(reads, 2);
    expect(t.calls.where((c) => c.uri.path.endsWith('/refresh')).length, 1);
  });
  test('logout during restored account read cannot reinstall rotated tokens or account', () async {
    final vault = MemorySessionVault();
    await vault.replace(TokenPair(access: 'old', refresh: 'old-refresh', expiresAt: DateTime(2000)));
    final account = Completer<ApiResponse>();
    final t = ScriptTransport((c) => c.uri.path.endsWith('/me') ? account.future : jsonReply(pair('new'))),
        api = client(t),
        session = SessionController(ApiAuthRepository(api), vault);
    api.session = session;
    addTearDown(session.dispose);
    final restored = session.restore();
    while (!t.calls.any((c) => c.uri.path.endsWith('/me'))) {
      await Future<void>.delayed(Duration.zero);
    }
    await session.signOut();
    account.complete(jsonReply(user));
    await restored;
    expect(session.stage, SessionStage.unauthenticated);
    expect(session.account, isNull);
    expect(await vault.read(), isNull);
  });
  test('storage cleanup failures do not strand loading or skip server logout', () async {
    final vault = FailingClearVault();
    final t = ScriptTransport((c) => jsonReply({}, status: c.uri.path.endsWith('/logout') ? 200 : 401)),
        api = client(t);
    final session = SessionController(ApiAuthRepository(api), vault);
    api.session = session;
    addTearDown(session.dispose);
    vault.value = TokenPair(access: 'old', refresh: 'old-refresh', expiresAt: DateTime(2030));
    await session.restore();
    expect(session.stage, SessionStage.expired);
    expect(session.failure!.kind, FailureKind.unavailable);
    session.tokens = vault.value;
    session.stage = SessionStage.authenticated;
    session.account = const Account(id: 'user-a', email: 'test@example.invalid', emailVerified: true);
    await session.signOut();
    expect(session.stage, SessionStage.unauthenticated);
    expect(t.calls.last.uri.path, '/v1/auth/logout');
    await session.expire();
    expect(session.stage, SessionStage.expired);
  });
  test('create replay preserves payload/key; PATCH presence and empty 204 are preserved', () async {
    final t = ScriptTransport(
          (c) => c.method == 'DELETE' ? ApiResponse(204, {}, const Stream.empty(), () {}) : jsonReply(note),
        ),
        api = client(t);
    signedIn(api);
    final repo = ApiKnowledgeRepository(api);
    const attempt = CreateAttempt(accountId: 'user-a', projectId: 'project-a', key: 'stable-key', content: 'A thought');
    for (var i = 0; i < 2; i++) {
      final n = await repo.createNote(attempt);
      expect(n.title, isNull);
      expect(n.isFavorite, isTrue);
      expect(n.processing, ProcessingState.queued);
    }
    expect(t.calls[0].headers['Idempotency-Key'], 'stable-key');
    expect(t.calls[1].json, t.calls[0].json);
    expect(t.calls[0].json, {'content': 'A thought', 'title': null});
    await repo.updateNote('user-a', 'note-a', const NotePatch(title: null, includesTitle: true));
    expect(t.calls.last.json, {'title': null});
    await repo.updateNote('user-a', 'note-a', const NotePatch(content: 'changed'));
    expect(t.calls.last.json, {'content': 'changed'});
    await repo.deleteNote('user-a', 'note-a');
    expect(t.calls.last.method, 'DELETE');
  });
  test('projects, note actions, graph, search, related and history use deployed shapes', () async {
    final t = ScriptTransport((c) {
          final p = c.uri.path;
          if (c.method == 'DELETE') return ApiResponse(204, {}, const Stream.empty(), () {});
          if (p.endsWith('/knowledge-graph')) {
            return jsonReply({
              'nodes': [
                {
                  'id': 'note-a',
                  'title': null,
                  'concepts': ['idea'],
                  'updated_at': '2026-11-27T00:00:00Z',
                },
              ],
              'edges': [
                {
                  'source_note_id': 'note-a',
                  'target_note_id': 'note-b',
                  'shared_concepts': ['idea'],
                },
              ],
            });
          }
          if (p.endsWith('/search')) {
            return jsonReply([
              {
                'note_id': 'note-a',
                'title': null,
                'content': 'A thought',
                'score': 1,
                'updated_at': '2026-11-27T00:00:00Z',
              },
            ]);
          }
          if (p.endsWith('/connections')) {
            return jsonReply([
              {'note_id': 'note-b', 'title': null},
            ]);
          }
          if (p.endsWith('/conversations')) return jsonReply(c.method == 'POST' ? conversation : [conversation]);
          if (p.startsWith('/v1/conversations/')) {
            return jsonReply({
              ...conversation,
              'messages': [message],
            });
          }
          if (p.endsWith('/notes')) return jsonReply([note]);
          if (p.startsWith('/v1/notes/')) return jsonReply(note);
          return jsonReply(c.method == 'GET' ? [project] : project);
        }),
        api = client(t);
    signedIn(api);
    final r = ApiKnowledgeRepository(api);
    expect((await r.projects('user-a')).single.id, 'project-a');
    await r.createProject('user-a', 'New');
    expect(t.calls.last.json, {'name': 'New'});
    await r.renameProject('user-a', 'project-a', 'Renamed');
    expect(t.calls.last.method, 'PATCH');
    await r.deleteProject('user-a', 'project-a');
    expect((await r.notes('user-a', 'project-a')).single.generation, 2);
    expect((await r.readNote('user-a', 'note-a')).content, 'A thought');
    await r.retryProcessing('user-a', 'note-a');
    expect(t.calls.last.json, isNull);
    expect((await r.setFavorite('user-a', 'note-a', false)).id, 'note-a');
    expect(t.calls.last.method, 'PUT');
    expect(t.calls.last.uri.path, '/v1/notes/note-a/favorite');
    expect(t.calls.last.json, {'is_favorite': false});
    for (final action in RefinementAction.values) {
      await r.refine('user-a', 'note-a', 2, action);
      expect(t.calls.last.json, {'expected_processing_generation': 2});
    }
    expect((await r.search('user-a', 'project-a', 'idea')).single.score, 1.0);
    expect((await r.graph('user-a', 'project-a')).edges.single.sharedConcepts, ['idea']);
    expect((await r.related('user-a', 'note-a')).single.noteId, 'note-b');
    await r.createConversation('user-a', 'project-a');
    expect(t.calls.last.json, {});
    expect((await r.conversations('user-a', 'project-a')).single.title, isNull);
    expect((await r.history('user-a', 'conversation-a')).messages.single.sources.single.noteId, 'note-a');
    await r.deleteConversation('user-a', 'conversation-a');
    expect(t.calls.last.method, 'DELETE');
    expect(t.calls.every((c) => c.headers['Authorization'] == 'Bearer access-old'), isTrue);
    expect(t.calls.every((c) => c.json is! Map || !(c.json as Map).containsKey('user_id')), isTrue);
  });
  test('network uncertainty never retries non-idempotent create or invents another note key', () async {
    final t = ScriptTransport((_) => throw const SocketException('lost')), api = client(t);
    signedIn(api);
    final repo = ApiKnowledgeRepository(api);
    await expectLater(repo.createProject('user-a', 'new'), throwsA(kind(FailureKind.uncertain)));
    expect(t.calls.length, 1);
    await expectLater(
      repo.createNote(const CreateAttempt(accountId: 'user-a', projectId: 'p', key: 'key', content: 'text')),
      throwsA(kind(FailureKind.uncertain)),
    );
    expect(t.calls.length, 2);
    expect(t.calls.last.headers['Idempotency-Key'], 'key');
  });
  test('quota, validation and non-JSON infrastructure errors are safe and route-aware', () async {
    final quota = ApiClient.failure(429, {'retry-after': '60'}, {'detail': 'secret input'});
    expect(quota.retryAfter, const Duration(seconds: 60));
    expect(quota.kind, FailureKind.quota);
    final validation = ApiClient.failure(422, {}, {
      'detail': [
        {
          'loc': ['body', 'email'],
          'input': 'private',
        },
      ],
    });
    expect(validation.field, 'email');
    expect(validation.toString(), isNot(contains('private')));
    final t = ScriptTransport(
          (_) => ApiResponse(503, {}, Stream.value(utf8.encode('<html>unavailable</html>')), () {}),
        ),
        api = client(t);
    await expectLater(api.request('GET', '/ready'), throwsA(kind(FailureKind.unavailable)));
  });
  test('SSE decodes split UTF-8 and treats complete as authoritative; incomplete EOF stays incomplete', () async {
    final complete = {
      'conversation': conversation,
      'user_message': {
        ...message,
        'id': 'user-message',
        'role': 'user',
        'content': 'Question',
        'supported': null,
        'sources': [],
      },
      'assistant_message': message,
    };
    final text =
        'event: delta\r\ndata: ${jsonEncode({'content': 'مرحبا'})}\r\n\r\nevent: complete\ndata: ${jsonEncode(complete)}\n\n';
    var closed = false;
    final t = ScriptTransport(
          (_) => ApiResponse(
            200,
            {'content-type': 'text/event-stream; charset=utf-8'},
            Stream.fromIterable(utf8.encode(text).map((b) => [b])),
            () {
              closed = true;
            },
          ),
        ),
        api = client(t);
    signedIn(api);
    final events = await ApiKnowledgeRepository(api).send('user-a', 'conversation-a', 'Question').toList();
    expect((events.first as ChatDelta).content, 'مرحبا');
    expect((events.last as ChatComplete).assistant.content, 'Final answer');
    expect(closed, isTrue);
    expect(t.calls.single.headers['Accept'], 'text/event-stream');
    expect(t.calls.single.json, {'content': 'Question'});
    final partial = client(
      ScriptTransport(
        (_) => ApiResponse(
          200,
          {'content-type': 'text/event-stream'},
          Stream.value(utf8.encode('event: complete\ndata: {}')),
          () {},
        ),
      ),
    );
    signedIn(partial);
    expect(await ApiKnowledgeRepository(partial).send('user-a', 'conversation-a', 'Question').toList(), isEmpty);
  });
  test('SSE cancellation closes a connection even while waiting for response headers', () async {
    final cancelled = Completer<void>();
    final api = ApiClient(Uri.parse('https://api.example.invalid'), transport: WaitingTransport(cancelled));
    signedIn(api);
    final subscription = ApiKnowledgeRepository(api).send('user-a', 'conversation-a', 'Question').listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    await cancelled.future;
  });
  test('recording upload sends one binary file part and no project/language fields', () async {
    final dir = await Directory.systemTemp.createTemp('fikrah-audio-test-');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/clip.m4a');
    await f.writeAsBytes([1, 2, 3, 255]);
    final t = ScriptTransport((_) => jsonReply({'text': 'Transcript'})), api = client(t);
    signedIn(api);
    expect(
      await ApiKnowledgeRepository(api)
          .transcribe('user-a', RecordedClip(f.path, 'audio/mp4', const Duration(seconds: 1))),
      'Transcript',
    );
    final call = t.calls.single, raw = latin1.decode(t.calls.single.bytes);
    expect(call.headers['Content-Type'], startsWith('multipart/form-data; boundary='));
    expect(raw, contains('name="file"'));
    expect(raw, contains('Content-Type: audio/mp4'));
    expect(raw, contains(latin1.decode([1, 2, 3, 255])));
    expect(raw, isNot(contains('project_id')));
    expect(raw, isNot(contains('language')));
  });
  test('secure session/attempt records survive new store instances and are account/origin isolated', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const vault = SecureSessionVault(key: 'api-a');
    final tokens = TokenPair(access: 'a', refresh: 'r', expiresAt: DateTime(2030));
    await vault.replace(tokens);
    expect((await const SecureSessionVault(key: 'api-a').read())!.refresh, 'r');
    expect(await const SecureSessionVault(key: 'api-b').read(), isNull);
    final attempts = SecureAttemptStore(namespace: 'api-a');
    const attempt = CreateAttempt(accountId: 'user-a', projectId: 'p', key: 'stable', content: 'private', title: null);
    await attempts.write(attempt);
    expect((await SecureAttemptStore(namespace: 'api-a').read('user-a'))!.samePayload(attempt), isTrue);
    expect(await attempts.read('user-b'), isNull);
    expect(await SecureAttemptStore(namespace: 'api-b').read('user-a'), isNull);
    await attempts.clear('user-a');
    await vault.clear();
    expect(await attempts.read('user-a'), isNull);
    expect(await vault.read(), isNull);
  });
  test('transport failures keep a safe connection category without exposing exception text', () async {
    for (final entry in <Object, FailureCause>{
      const SocketException('private network details'): FailureCause.connection,
      TimeoutException('private timeout details'): FailureCause.timeout,
      const HandshakeException('private certificate details'): FailureCause.secureConnection,
    }.entries) {
      final api = client(ScriptTransport((_) => throw entry.key));
      await expectLater(
        api.request('POST', '/v1/auth/login', json: {'password': 'never-log-this'}),
        throwsA(
          isA<ProductFailure>()
              .having((f) => f.cause, 'cause', entry.value)
              .having((f) => f.toString().contains('private'), 'no private details', false),
        ),
      );
    }
    final api = client(ScriptTransport((_) => jsonReply({'detail': 'private error'}, status: 503)));
    await expectLater(
      api.request('POST', '/v1/auth/register/otp'),
      throwsA(isA<ProductFailure>().having((f) => f.status, 'status', 503)),
    );
  });

  test('native transport sends bytes and does not follow a redirect', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var received = 0;
    server.listen((request) async {
      received++;
      expect(await utf8.decoder.bind(request).join(), '{"input":"hello"}');
      request.response.statusCode = 307;
      request.response.headers.set('location', '/redirected');
      await request.response.close();
    });
    final cancel = ApiCancellation();
    final response = await HttpOverrides.runWithHttpOverrides(
      () => NativeApiTransport().send(
        'POST',
        Uri.parse('http://127.0.0.1:${server.port}/test'),
        {'Accept': 'application/json'},
        ApiBody.json({'input': 'hello'}),
        cancel,
      ),
      NativeHttpOverrides(),
    );
    expect(response.status, 307);
    await response.body.drain<void>();
    response.close();
    cancel.cancel();
    expect(received, 1);
  });
}

class WaitingTransport implements ApiTransport {
  WaitingTransport(this.cancelled);
  final Completer<void> cancelled;
  @override
  Future<ApiResponse> send(String m, Uri uri, Map<String, String> h, ApiBody? b, ApiCancellation c) {
    final result = Completer<ApiResponse>();
    c.listen(() {
      if (!cancelled.isCompleted) cancelled.complete();
      if (!result.isCompleted) result.completeError(const ProductFailure(FailureKind.uncertain));
    });
    return result.future;
  }
}

class NativeHttpOverrides extends HttpOverrides {}

class FailingClearVault extends MemorySessionVault {
  @override
  Future<void> clear() async => throw const ProductFailure(FailureKind.unavailable);
}
