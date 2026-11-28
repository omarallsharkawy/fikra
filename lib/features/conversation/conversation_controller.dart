import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/product/models.dart';
import '../../data/product/repositories.dart';

enum SendState { idle, sending, uncertain, reconciling, reviewed }

class ConversationController extends ChangeNotifier {
  ConversationController(
    this.repository, {
    this.sendLimit = const Duration(minutes: 3),
    this.previewThrottle = const Duration(milliseconds: 50),
    this.onUnauthorized,
  });
  final KnowledgeRepository repository;
  final Duration sendLimit;
  final Duration previewThrottle;
  final VoidCallback? onUnauthorized;
  String? accountId, projectId;
  List<Conversation> conversations = const [];
  ConversationHistory? current;
  String draft = '';
  final ValueNotifier<int> draftListenable = ValueNotifier<int>(0);
  final ValueNotifier<String> previewListenable = ValueNotifier<String>('');
  final StringBuffer _previewBuffer = StringBuffer();
  String get preview => previewListenable.value;
  bool loading = false;
  ProductFailure? failure;
  SendState sendState = SendState.idle;
  DateTime? retryAt;
  int _epoch = 0;
  bool _disposed = false;
  StreamSubscription<ChatEvent>? _subscription;
  Timer? _deadline, _retryWake, _previewTimer;
  Completer<void>? _sendDone;
  final _uncertain = <String>{};
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _bumpDraft() {
    if (!_disposed) draftListenable.value++;
  }

  void _flushPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    if (_disposed) return;
    final text = _previewBuffer.toString();
    if (previewListenable.value != text) previewListenable.value = text;
  }

  void _appendPreview(String chunk) {
    if (chunk.isEmpty) return;
    final wasEmpty = _previewBuffer.isEmpty;
    _previewBuffer.write(chunk);
    if (wasEmpty || previewThrottle <= Duration.zero) {
      _flushPreview();
    } else {
      _previewTimer ??= Timer(previewThrottle, _flushPreview);
    }
  }

  void _clearPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    _previewBuffer.clear();
    if (!_disposed && previewListenable.value.isNotEmpty) {
      previewListenable.value = '';
    }
  }

  bool _valid(int ticket) => !_disposed && ticket == _epoch && accountId != null;
  ProductFailure _error(Object error) {
    final value = ProductFailure.from(error);
    if (value.kind == FailureKind.unauthorized) onUnauthorized?.call();
    if (value.kind == FailureKind.quota && value.retryAfter != null) {
      retryAt = DateTime.now().add(value.retryAfter!);
      _retryWake?.cancel();
      _retryWake = Timer(value.retryAfter!, _emit);
    }
    return value;
  }

  void reset() {
    _epoch++;
    _stop();
    accountId = null;
    projectId = null;
    current = null;
    conversations = const [];
    draft = '';
    _bumpDraft();
    _clearPreview();
    failure = null;
    loading = false;
    sendState = SendState.idle;
    _uncertain.clear();
    _retryWake?.cancel();
    retryAt = null;
    _emit();
  }

  Future<void> selectProject(String account, String project) async {
    _epoch++;
    _stop();
    accountId = account;
    projectId = project;
    current = null;
    conversations = const [];
    draft = '';
    _bumpDraft();
    _clearPreview();
    failure = null;
    sendState = SendState.idle;
    await reloadList();
  }

  Future<void> reloadList() async {
    final account = accountId, project = projectId, ticket = _epoch;
    if (account == null || project == null) return;
    loading = true;
    failure = null;
    _emit();
    try {
      final list = await repository.conversations(account, project);
      if (_valid(ticket)) conversations = List.unmodifiable(list);
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> create() async {
    final account = accountId, project = projectId, ticket = _epoch;
    if (account == null || project == null || loading || sendState == SendState.sending) return;
    loading = true;
    failure = null;
    _emit();
    try {
      final conversation = await repository.createConversation(account, project);
      if (!_valid(ticket)) return;
      conversations = [conversation, ...conversations];
      current = ConversationHistory(conversation, const []);
      _clearPreview();
      draft = '';
      _bumpDraft();
      sendState = SendState.idle;
    } catch (error) {
      if (_valid(ticket)) {
        final problem = _error(error);
        failure = problem;
        // Uncertain create is never retried automatically. Reload the list first.
        if (problem.kind == FailureKind.uncertain) {
          loading = false;
          await reloadList();
          if (_valid(ticket)) failure = problem;
        }
      }
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> open(String id) async {
    final account = accountId, ticket = ++_epoch;
    _stop();
    current = null;
    draft = '';
    _bumpDraft();
    _clearPreview();
    failure = null;
    sendState = SendState.idle;
    if (account == null) return;
    loading = true;
    _emit();
    try {
      final history = await repository.history(account, id);
      if (!_valid(ticket)) return;
      if (history.conversation.projectId != projectId) throw const ProductFailure(FailureKind.notFound);
      current = history;
      sendState = _uncertain.contains(id) ? SendState.reviewed : SendState.idle;
      _uncertain.remove(id);
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  void updateDraft(String value) {
    if (draft == value) return;
    draft = value;
    _bumpDraft();
  }

  bool get canSend =>
      current != null &&
      !loading &&
      sendState != SendState.sending &&
      sendState != SendState.uncertain &&
      sendState != SendState.reconciling &&
      draft.trim().isNotEmpty &&
      (retryAt == null || !DateTime.now().isBefore(retryAt!));
  Future<void> send() async {
    final account = accountId, history = current, ticket = _epoch;
    if (account == null || history == null || !canSend) return;
    final text = draft.trim();
    if (text.runes.length > 4000) {
      failure = const ProductFailure(FailureKind.validation);
      _emit();
      return;
    }
    sendState = SendState.sending;
    _clearPreview();
    failure = null;
    final done = Completer<void>();
    _sendDone = done;
    _emit();
    void uncertain(Object error) {
      if (!_valid(ticket) || sendState != SendState.sending) return;
      failure = _error(error);
      sendState = SendState.uncertain;
      _uncertain.add(history.conversation.id);
      _stop();
      _emit();
    }

    _deadline = Timer(sendLimit, () => uncertain(const ProductFailure(FailureKind.uncertain)));
    _subscription = repository
        .send(account, history.conversation.id, text)
        .listen(
          (event) {
            if (!_valid(ticket) || sendState != SendState.sending) return;
            switch (event) {
              case ChatDelta():
                _appendPreview(event.content);
                return;
              case ChatError():
                uncertain(event.failure);
                return;
              case ChatComplete():
                if (event.conversation.id != history.conversation.id || event.conversation.projectId != projectId) {
                  uncertain(const ProductFailure(FailureKind.uncertain));
                  return;
                }
                final baseMessages = current?.conversation.id == history.conversation.id
                    ? current!.messages
                    : history.messages;
                final byId = {
                  for (final m in baseMessages) m.id: m,
                  event.user.id: event.user,
                  event.assistant.id: event.assistant,
                };
                current = ConversationHistory(event.conversation, List.unmodifiable(byId.values));
                conversations = [event.conversation, ...conversations.where((c) => c.id != event.conversation.id)];
                if (draft.trim() == text) {
                  draft = '';
                  _bumpDraft();
                }
                _clearPreview();
                sendState = SendState.idle;
                _uncertain.remove(history.conversation.id);
                _stop();
            }
            _emit();
          },
          onError: (Object error) => uncertain(error),
          onDone: () {
            if (_valid(ticket) && sendState == SendState.sending) {
              uncertain(const ProductFailure(FailureKind.uncertain));
            }
          },
        );
    await done.future;
  }

  Future<void> reconcile() async {
    final account = accountId, history = current, ticket = _epoch;
    if (account == null ||
        history == null ||
        sendState == SendState.sending ||
        sendState == SendState.reconciling ||
        loading) {
      return;
    }
    sendState = SendState.reconciling;
    failure = null;
    _emit();
    try {
      final loaded = await repository.history(account, history.conversation.id);
      if (!_valid(ticket)) return;
      if (loaded.conversation.projectId != projectId) throw const ProductFailure(FailureKind.notFound);
      current = loaded;
      _clearPreview();
      sendState = SendState.reviewed;
      _uncertain.remove(history.conversation.id);
      // Keep the draft. User reviews authoritative history before any new send.
    } catch (error) {
      if (_valid(ticket)) {
        final problem = _error(error);
        failure = problem;
        if (problem.kind == FailureKind.notFound) {
          conversations = conversations.where((c) => c.id != history.conversation.id).toList();
          _uncertain.remove(history.conversation.id);
          current = null;
          _clearPreview();
          sendState = SendState.idle;
        } else {
          sendState = SendState.uncertain;
        }
      }
    } finally {
      if (_valid(ticket)) _emit();
    }
  }

  void invalidateNoteReferences(Set<String> accessibleIds) {
    final history = current;
    if (history == null) return;
    current = ConversationHistory(history.conversation, [
      for (final message in history.messages)
        KnowledgeMessage(
          id: message.id,
          role: message.role,
          content: message.content,
          supported: message.supported,
          createdAt: message.createdAt,
          sources: message.sources.where((s) => accessibleIds.contains(s.noteId)).toList(),
        ),
    ]);
    _emit();
  }

  void interrupt() {
    if (sendState != SendState.sending || current == null) return;
    _uncertain.add(current!.conversation.id);
    sendState = SendState.uncertain;
    failure = const ProductFailure(FailureKind.uncertain);
    _stop();
    _emit();
  }

  Future<bool> deleteCurrent() async {
    final account = accountId, history = current, ticket = _epoch;
    if (account == null || history == null || loading || sendState == SendState.sending) return false;
    loading = true;
    failure = null;
    _emit();
    try {
      await repository.deleteConversation(account, history.conversation.id);
      if (!_valid(ticket)) return false;
      conversations = conversations.where((c) => c.id != history.conversation.id).toList();
      _uncertain.remove(history.conversation.id);
      current = null;
      draft = '';
      _bumpDraft();
      _clearPreview();
      sendState = SendState.idle;
      return true;
    } catch (error) {
      if (_valid(ticket)) failure = _error(error);
      return false;
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  void _stop() {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) unawaited(sub.cancel().catchError((Object _) {}));
    _deadline?.cancel();
    _deadline = null;
    if (_sendDone != null && !_sendDone!.isCompleted) _sendDone!.complete();
    _sendDone = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _retryWake?.cancel();
    _previewTimer?.cancel();
    _epoch++;
    _stop();
    draftListenable.dispose();
    previewListenable.dispose();
    super.dispose();
  }
}
