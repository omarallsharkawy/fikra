import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fikra/data/product/api/api_auth.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/api/api_knowledge.dart';
import 'package:fikra/data/product/chat_frames.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/conversation/conversation_controller.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubTransport implements ApiTransport {
  _StubTransport(this.handler);
  final FutureOr<ApiResponse> Function(String method, Uri uri, Map<String, String> headers) handler;

  @override
  Future<ApiResponse> send(
    String method,
    Uri uri,
    Map<String, String> headers,
    ApiBody? body,
    ApiCancellation cancel,
  ) async => await handler(method, uri, headers);
}

ApiResponse _json(Object? body, {int status = 200, Map<String, String> headers = const {}}) => ApiResponse(
  status,
  {'content-type': 'application/json', ...headers},
  Stream.value(utf8.encode(jsonEncode(body))),
  () {},
);

class _DelayedLogoutAuth extends DevelopmentAuthRepository {
  final logoutGate = Completer<bool>();
  @override
  Future<bool> logout(TokenPair? tokens) => logoutGate.future;
}

class _OverlappingReloadRepo extends DevelopmentKnowledgeRepository {
  int calls = 0;
  final firstCall = Completer<List<KnowledgeNote>>();
  final secondCall = Completer<List<KnowledgeNote>>();

  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) {
    calls++;
    if (calls == 2) return firstCall.future;
    if (calls == 3) return secondCall.future;
    return super.notes(accountId, projectId);
  }
}

class _TransientPollRepo extends DevelopmentKnowledgeRepository {
  bool failNextRead = true;
  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async {
    if (failNextRead) {
      failNextRead = false;
      throw const ProductFailure(FailureKind.uncertain, cause: FailureCause.connection);
    }
    return super.readNote(accountId, noteId);
  }
}

class _DeletedConvRepo extends DevelopmentKnowledgeRepository {
  bool deleteOnHistory = false;
  @override
  Future<ConversationHistory> history(String accountId, String conversationId) async {
    if (deleteOnHistory) throw const ProductFailure(FailureKind.notFound);
    return super.history(accountId, conversationId);
  }
}

void main() {
  group('Phase 3 network, auth, and concurrency hardening', () {
    test('HTTP 403 maps to forbidden on protected routes and unverified only on login', () async {
      final api = ApiClient(
        Uri.parse('https://api.example.invalid'),
        transport: _StubTransport((_, _, _) => _json({'detail': 'Forbidden'}, status: 403)),
      );
      await expectLater(
        api.request('GET', '/v1/projects'),
        throwsA(isA<ProductFailure>().having((e) => e.kind, 'kind', FailureKind.forbidden)),
      );
      await expectLater(
        api.request('POST', '/v1/auth/login', json: {'email': 'a@b.c', 'password': 'x'}),
        throwsA(isA<ProductFailure>().having((e) => e.kind, 'kind', FailureKind.unverified)),
      );
    });

    test('ApiClient.failure selects first validation field and clamps HTTP-date Retry-After', () {
      final multi = ApiClient.failure(422, const {}, {
        'detail': [
          {
            'loc': ['body', 'email'],
          },
          {
            'loc': ['body', 'password'],
          },
        ],
      });
      expect(multi.field, 'email');

      final farFuture = HttpDate.format(DateTime.now().toUtc().add(const Duration(days: 30)));
      final quota = ApiClient.failure(429, {'retry-after': farFuture}, const {});
      expect(quota.retryAfter, isNotNull);
      expect(quota.retryAfter!, lessThanOrEqualTo(const Duration(minutes: 15)));
    });

    test('ApiAuthRepository reports invalidResponse on malformed JSON payload', () async {
      final api = ApiClient(
        Uri.parse('https://api.example.invalid'),
        transport: _StubTransport((_, _, _) => _json({'unexpected': true})),
      );
      final auth = ApiAuthRepository(api);
      await expectLater(
        auth.login('user@example.invalid', 'secret'),
        throwsA(
          isA<ProductFailure>()
              .having((e) => e.kind, 'kind', FailureKind.unavailable)
              .having((e) => e.cause, 'cause', FailureCause.invalidResponse),
        ),
      );
    });

    test('decodeChatFrames strips leading UTF-8 BOM and enforces max frame size', () async {
      final frames = await decodeChatFrames(
        Stream.value(utf8.encode('\uFEFFevent: delta\ndata: {"content":"hi"}\n\n')),
      ).toList();
      expect(frames.single.event, 'delta');
      expect(frames.single.payload['content'], 'hi');

      final huge = 'x' * (2 * 1024 * 1024 + 10);
      await expectLater(
        decodeChatFrames(Stream.value(utf8.encode('event: delta\ndata: $huge\n\n'))).toList(),
        throwsFormatException,
      );
    });

    test('ApiKnowledgeRepository.send handles uppercase content-type and SSE error retry_after', () async {
      final api = ApiClient(
        Uri.parse('https://api.example.invalid'),
        transport: _StubTransport(
          (_, _, _) => ApiResponse(
            200,
            {'content-type': 'Text/Event-Stream; charset=utf-8'},
            Stream.value(utf8.encode('event: error\ndata: {"status":429,"retry_after":45}\n\n')),
            () {},
          ),
        ),
      );
      final session = SessionController(DevelopmentAuthRepository(), MemorySessionVault());
      addTearDown(session.dispose);
      session.account = const Account(id: 'u1', email: 'u1@example.invalid', emailVerified: true);
      session.tokens = TokenPair(access: 'tok', refresh: 'ref', expiresAt: DateTime(2030));
      session.stage = SessionStage.authenticated;
      api.session = session;

      final events = await ApiKnowledgeRepository(api).send('u1', 'c1', 'hi').toList();
      final err = events.single as ChatError;
      expect(err.failure.kind, FailureKind.quota);
      expect(err.failure.retryAfter, const Duration(seconds: 45));
    });

    test('delayed signOut logout cannot overwrite notice after a new login, and confirmRecovery keeps reset notice', () async {
      final auth = _DelayedLogoutAuth();
      final s = SessionController(auth, MemorySessionVault());
      addTearDown(s.dispose);
      await s.login('reader@example.invalid', 'fixture-only');
      final signingOut = s.signOut();
      await Future<void>.delayed(Duration.zero);
      await s.login('other@example.invalid', 'fixture-only');
      expect(s.stage, SessionStage.authenticated);
      auth.logoutGate.complete(true);
      await signingOut;
      expect(s.stage, SessionStage.authenticated);
      expect(s.notice, isNull);

      await s.recover('other@example.invalid');
      await s.confirmRecovery('fixture-reset', 'new-password');
      expect(s.stage, SessionStage.unauthenticated);
      expect(s.notice, 'reset');
      expect(s.busy, isFalse);
    });

    test('WorkspaceController reload sequence fences older response, rename keeps order, poll keeps search', () async {
      final overlapRepo = _OverlappingReloadRepo();
      final w = WorkspaceController(overlapRepo, MemoryAttemptStore());
      addTearDown(w.dispose);
      await w.openAccount('development-reader');
      final originalNotes = w.notes;

      final first = w.reload();
      final second = w.reload();
      overlapRepo.secondCall.complete([originalNotes.first]);
      await second;
      expect(w.notes.length, 1);
      overlapRepo.firstCall.complete(originalNotes);
      await first;
      expect(w.notes.length, 1);

      // Rename preserves project ordering.
      await w.saveProject('Alpha');
      await w.saveProject('Beta');
      final alphaId = w.projects.firstWhere((p) => p.name == 'Alpha').id;
      final indexBefore = w.projects.indexWhere((p) => p.id == alphaId);
      await w.saveProject('Alpha Renamed', id: alphaId);
      expect(w.projects.indexWhere((p) => p.id == alphaId), indexBefore);

      // Poll preserves active search results & does not poison workspace.failure on transient blip.
      final pollRepo = _TransientPollRepo();
      final w2 = WorkspaceController(pollRepo, MemoryAttemptStore(), pollInterval: const Duration(days: 1));
      addTearDown(w2.dispose);
      await w2.openAccount('development-reader');
      final existingWord = w2.notes.first.content.split(RegExp(r'\s+')).firstWhere((t) => t.length > 3);
      w2.updateDraft(content: 'fresh pending note');
      await w2.save();
      await w2.search(existingWord);
      expect(w2.results, isNotEmpty);
      await w2.pollNow(); // transient failure
      expect(w2.failure, isNull);
      expect(w2.results, isNotEmpty);
      await w2.pollNow(); // processing
      await w2.pollNow(); // completed
      expect(w2.results, isNotEmpty);
    });

    test('ConversationController reconcile clears current on 404 instead of looping', () async {
      final repo = _DeletedConvRepo();
      final c = ConversationController(repo);
      addTearDown(c.dispose);
      final project = (await repo.projects('development-other')).first;
      await c.selectProject('development-other', project.id);
      await c.create();
      c.sendState = SendState.uncertain;
      repo.deleteOnHistory = true;

      await c.reconcile();
      expect(c.current, isNull);
      expect(c.sendState, SendState.idle);
      expect(c.failure?.kind, FailureKind.notFound);
    });

    test('NativeApiTransport releases unlistened response sockets and handles mid-stream cancel', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((req) async {
        if (req.uri.path == '/401') {
          req.response.statusCode = 401;
          req.response.write('{"detail":"expired"}');
          await req.response.close();
          return;
        }
        req.response.statusCode = 200;
        req.response.bufferOutput = false;
        req.response.headers.contentType = ContentType('text', 'event-stream');
        req.response.write('event: delta\ndata: {"content":"part1"}\n\n');
        await req.response.flush();
        // Hold open until client cancels.
        await Future<void>.delayed(const Duration(seconds: 5));
        try {
          await req.response.close();
        } catch (_) {}
      });

      final transport = NativeApiTransport();
      addTearDown(transport.close);
      final base = Uri.parse('http://127.0.0.1:${server.port}');

      // Closing many unlistened 401 responses must release sockets cleanly without stalling the pool.
      for (var i = 0; i < 12; i++) {
        final cancel = ApiCancellation();
        final res = await transport.send('GET', base.resolve('/401'), const {}, null, cancel);
        expect(res.status, 401);
        res.close();
      }

      // Cancelling an active stream closes response.body promptly without hanging.
      final cancel = ApiCancellation();
      final res = await transport.send('GET', base.resolve('/stream'), const {}, null, cancel);
      final received = <String>[];
      final done = Completer<void>();
      res.body.transform(utf8.decoder).listen(
        (chunk) {
          received.add(chunk);
          cancel.cancel();
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 2));
      expect(received, isNotEmpty);
    });

    test('pollNow halts on quota (429) and forbidden (403) instead of hammering server', () async {
      for (final kind in [FailureKind.quota, FailureKind.forbidden]) {
        final repo = _FixedPollFailureRepo(kind);
        final w = WorkspaceController(repo, MemoryAttemptStore(), pollInterval: const Duration(milliseconds: 5));
        addTearDown(w.dispose);
        await w.openAccount('development-other');
        w.updateDraft(content: 'Pending note');
        await w.save();
        await w.pollNow();
        expect(w.failure?.kind, kind);
        final callsAfter = repo.readCalls;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(repo.readCalls, callsAfter);
      }
    });
  });
}

class _FixedPollFailureRepo extends DevelopmentKnowledgeRepository {
  _FixedPollFailureRepo(this.kind);
  final FailureKind kind;
  int readCalls = 0;

  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async {
    readCalls++;
    throw ProductFailure(kind, retryAfter: kind == FailureKind.quota ? const Duration(seconds: 60) : null);
  }
}
