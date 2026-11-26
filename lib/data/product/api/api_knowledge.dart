import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../ids.dart';
import '../chat_frames.dart';
import '../models.dart';
import '../repositories.dart';
import 'api_client.dart';
import 'api_models.dart';

class ApiKnowledgeRepository implements KnowledgeRepository {
  ApiKnowledgeRepository(this.api);
  final ApiClient api;
  String _id(String value) => Uri.encodeComponent(value);
  Future<T> _one<T>(
    String method,
    String path,
    String account,
    T Function(dynamic) decode, {
    Object? json,
    Map<String, String> headers = const {},
    ApiBody? body,
  }) async {
    final result = await api.request(method, path, accountId: account, json: json, headers: headers, body: body);
    try {
      return decode(result);
    } catch (_) {
      throw const ProductFailure(FailureKind.unavailable);
    }
  }

  Future<List<T>> _list<T>(String method, String path, String account, T Function(dynamic) decode, {Object? json}) =>
      _one(method, path, account, (x) => [for (final v in x as List) decode(v)], json: json);
  @override
  Future<List<KnowledgeProject>> projects(String a) => _list('GET', '/v1/projects', a, projectFromJson);
  @override
  Future<KnowledgeProject> createProject(String a, String name) =>
      _one('POST', '/v1/projects', a, projectFromJson, json: {'name': name});
  @override
  Future<KnowledgeProject> renameProject(String a, String id, String name) =>
      _one('PATCH', '/v1/projects/${_id(id)}', a, projectFromJson, json: {'name': name});
  @override
  Future<void> deleteProject(String a, String id) async {
    await api.request('DELETE', '/v1/projects/${_id(id)}', accountId: a);
  }

  @override
  Future<List<KnowledgeNote>> notes(String a, String p) =>
      _list('GET', '/v1/projects/${_id(p)}/notes', a, noteFromJson);
  @override
  Future<KnowledgeNote> readNote(String a, String id) => _one('GET', '/v1/notes/${_id(id)}', a, noteFromJson);
  @override
  Future<KnowledgeNote> createNote(CreateAttempt t) => _one(
    'POST',
    '/v1/projects/${_id(t.projectId)}/notes',
    t.accountId,
    noteFromJson,
    json: {'content': t.content, 'title': t.title},
    headers: {'Idempotency-Key': t.key},
  );
  @override
  Future<KnowledgeNote> updateNote(String a, String id, NotePatch patch) =>
      _one('PATCH', '/v1/notes/${_id(id)}', a, noteFromJson, json: patch.fields);
  @override
  Future<void> deleteNote(String a, String id) async {
    await api.request('DELETE', '/v1/notes/${_id(id)}', accountId: a);
  }

  @override
  Future<KnowledgeNote> retryProcessing(String a, String id) =>
      _one('POST', '/v1/notes/${_id(id)}/processing-retries', a, noteFromJson);
  @override
  Future<KnowledgeNote> refine(String a, String id, int generation, RefinementAction action) {
    final suffix = switch (action) {
      RefinementAction.accept => 'refinement-acceptance',
      RefinementAction.reject => 'refinement-rejections',
      RefinementAction.regenerate => 'refinement-regenerations',
    };
    return _one(
      'POST',
      '/v1/notes/${_id(id)}/$suffix',
      a,
      noteFromJson,
      json: {'expected_processing_generation': generation},
    );
  }

  @override
  Future<List<NoteSearchResult>> search(String a, String p, String query) =>
      _list('POST', '/v1/projects/${_id(p)}/search', a, (v) {
        final x = object(v);
        return NoteSearchResult(
          noteId: x['note_id'],
          title: x['title'],
          content: x['content'],
          score: (x['score'] as num).toDouble(),
        );
      }, json: {'query': query});
  @override
  Future<KnowledgeGraph> graph(String a, String p) =>
      _one('GET', '/v1/projects/${_id(p)}/knowledge-graph', a, graphFromJson);
  @override
  Future<List<NoteSourceReference>> related(String a, String id) =>
      _list('GET', '/v1/notes/${_id(id)}/connections', a, sourceFromJson);
  @override
  Future<List<Conversation>> conversations(String a, String p) =>
      _list('GET', '/v1/projects/${_id(p)}/conversations', a, conversationFromJson);
  @override
  Future<Conversation> createConversation(String a, String p) =>
      _one('POST', '/v1/projects/${_id(p)}/conversations', a, conversationFromJson, json: const <String, Object?>{});
  @override
  Future<ConversationHistory> history(String a, String id) => _one('GET', '/v1/conversations/${_id(id)}', a, (v) {
    final x = object(v);
    return ConversationHistory(conversationFromJson(x), [for (final m in x['messages'] as List) messageFromJson(m)]);
  });
  @override
  Future<void> deleteConversation(String a, String id) async {
    await api.request('DELETE', '/v1/conversations/${_id(id)}', accountId: a);
  }

  @override
  Stream<ChatEvent> send(String a, String id, String text) {
    final cancel = ApiCancellation();
    ApiResponse? response;
    late StreamController<ChatEvent> output;
    Future<void> run() async {
      try {
        response = await api.open(
          'POST',
          '/v1/conversations/${_id(id)}/messages/stream',
          accountId: a,
          json: {'content': text},
          accept: 'text/event-stream',
          cancellation: cancel,
        );
        if (cancel.cancelled) return;
        if (response!.status != 200) {
          dynamic payload;
          try {
            payload = jsonDecode(await utf8.decoder.bind(response!.body).join().timeout(api.timeout));
          } catch (_) {}
          throw ApiClient.failure(response!.status, response!.headers, payload);
        }
        if (response!.headers['content-type']?.split(';').first.trim() != 'text/event-stream') {
          throw const ProductFailure(FailureKind.unavailable);
        }
        final coordinator = api.session;
        final epoch = coordinator?.epoch;
        await for (final frame in decodeChatFrames(response!.body).timeout(api.timeout)) {
          if (cancel.cancelled) break;
          if (api.session?.epoch != epoch || api.session?.account?.id != a) {
            throw const ProductFailure(FailureKind.unauthorized);
          }
          final x = frame.payload;
          if (frame.event == 'delta') output.add(ChatDelta(x['content'] as String));
          if (frame.event == 'complete') {
            output.add(
              ChatComplete(
                conversationFromJson(x['conversation']),
                messageFromJson(x['user_message']),
                messageFromJson(x['assistant_message']),
              ),
            );
            break;
          }
          if (frame.event == 'error') {
            output.add(ChatError(ApiClient.failure((x['status'] as num?)?.toInt() ?? 503, const {}, x)));
            break;
          }
        }
      } catch (error) {
        if (!cancel.cancelled) output.addError(ProductFailure.from(error));
      } finally {
        response?.close();
        if (!cancel.cancelled) await output.close();
      }
    }

    output = StreamController<ChatEvent>(
      onListen: () => unawaited(run()),
      onCancel: () {
        cancel.cancel();
        response?.close();
      },
    );
    return output.stream;
  }

  @override
  Future<String> transcribe(String a, RecordedClip clip) async {
    const supported = {
      'audio/wav',
      'audio/x-wav',
      'audio/mp3',
      'audio/mpeg',
      'audio/mp4',
      'audio/m4a',
      'audio/x-m4a',
      'audio/aac',
      'audio/ogg',
      'audio/flac',
      'audio/webm',
    };
    if (!supported.contains(clip.mimeType)) throw const ProductFailure(FailureKind.mediaType);
    final file = File(clip.path), boundary = 'fikrah-${newId()}';
    final head = utf8.encode(
      '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="recording"\r\nContent-Type: ${clip.mimeType}\r\n\r\n',
    );
    final tail = utf8.encode('\r\n--$boundary--\r\n');
    final body = ApiBody(
      'multipart/form-data; boundary=$boundary',
      head.length + await file.length() + tail.length,
      () async* {
        yield head;
        yield* file.openRead();
        yield tail;
      },
    );
    return _one('POST', '/v1/transcriptions', a, (x) => object(x)['text'] as String, body: body);
  }

  @override
  void clearAccount(String accountId) {} // No private response cache is kept here.
}
