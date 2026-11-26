import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';
import 'repositories.dart';

/// Account- and API-scoped write-ahead record. Never touches the legacy DB.
class SecureAttemptStore implements AttemptStore {
  SecureAttemptStore({required this.namespace, this.storage = const FlutterSecureStorage()});
  final String namespace;
  final FlutterSecureStorage storage;
  final _queues = <String, Future<void>>{};
  Future<T> _serial<T>(String accountId, Future<T> Function() work) {
    final result = (_queues[accountId] ?? Future<void>.value()).then((_) => work());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _queues[accountId] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_queues[accountId], tail)) _queues.remove(accountId);
      }),
    );
    return result;
  }

  String _key(String a) => 'fikrah_attempt:$namespace:$a';
  @override
  Future<CreateAttempt?> read(String accountId) => _serial(accountId, () async {
    final raw = await storage.read(key: _key(accountId));
    if (raw == null) return null;
    final x = jsonDecode(raw) as Map<String, dynamic>;
    if (x['account_id'] != accountId) throw const ProductFailure(FailureKind.conflict);
    return CreateAttempt(
      accountId: accountId,
      projectId: x['project_id'],
      key: x['key'],
      content: x['content'],
      title: x['title'],
    );
  });

  @override
  Future<void> write(CreateAttempt t) => _serial(
    t.accountId,
    () => storage.write(
      key: _key(t.accountId),
      value: jsonEncode({
        'account_id': t.accountId,
        'project_id': t.projectId,
        'key': t.key,
        'content': t.content,
        'title': t.title,
      }),
    ),
  );
  @override
  Future<void> clear(String a) => _serial(a, () => storage.delete(key: _key(a)));
}
