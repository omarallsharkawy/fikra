import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../data/product/local_ui_store.dart';
import '../../data/product/models.dart';

/// Unsupported profile fields stay explicitly on this device, per account.
class ProfileController extends ChangeNotifier {
  ProfileController(this.store);
  final LocalUiStore store;
  String? accountId, name;
  bool loading = false, promptSeen = false, busy = false;
  ProductFailure? failure;
  int _epoch = 0;
  bool _disposed = false;
  static bool validName(String value) => value.trim().isNotEmpty && value.trim().characters.length <= 40;
  String get initial => name == null || name!.isEmpty ? 'F' : name!.characters.first.toUpperCase();
  bool get needsNamePrompt => !loading && !promptSeen && name == null && accountId != null;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  bool _valid(int ticket) => !_disposed && ticket == _epoch;

  Future<void> bind(String? id, String email) async {
    final ticket = ++_epoch;
    accountId = id;
    name = null;
    promptSeen = false;
    loading = id != null;
    busy = false;
    failure = null;
    _emit();
    if (id == null) return;
    try {
      final record = await store.read('account:$id');
      final pending = await store.read('registration:${email.trim().toLowerCase()}');
      if (!_valid(ticket)) return;
      final saved = record['display_name'], staged = pending['display_name'];
      var resolved = saved is String && validName(saved) ? saved.trim() : null;
      if (resolved == null && staged is String && validName(staged)) {
        resolved = staged.trim();
        await store.update('account:$id', (r) => r['display_name'] = resolved);
        await store.update('registration:${email.trim().toLowerCase()}', (r) => r.remove('display_name'));
      }
      if (!_valid(ticket)) return;
      name = resolved;
      promptSeen = record['name_prompt_seen'] == true || resolved != null;
    } catch (_) {
      if (_valid(ticket)) failure = const ProductFailure(FailureKind.unavailable);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<bool> stageRegistration(String email, String value) async {
    if (!validName(value)) return false;
    try {
      await store.update('registration:${email.trim().toLowerCase()}', (r) => r['display_name'] = value.trim());
      return true;
    } catch (_) {
      if (!_disposed) {
        failure = const ProductFailure(FailureKind.unavailable);
        _emit();
      }
      return false;
    }
  }

  Future<bool> setName(String value) async {
    final id = accountId, ticket = _epoch;
    if (id == null || busy || !validName(value)) return false;
    busy = true;
    failure = null;
    _emit();
    try {
      await store.update('account:$id', (r) {
        r['display_name'] = value.trim();
        r['name_prompt_seen'] = true;
      });
      if (!_valid(ticket)) return false;
      name = value.trim();
      promptSeen = true;
      return true;
    } catch (_) {
      if (_valid(ticket)) failure = const ProductFailure(FailureKind.unavailable);
      return false;
    } finally {
      if (_valid(ticket)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<bool> claimNamePrompt() async {
    final id = accountId;
    if (!needsNamePrompt || id == null) return false;
    promptSeen = true;
    _emit();
    try {
      await store.update('account:$id', (r) => r['name_prompt_seen'] = true);
    } catch (_) {
      /* No repeated prompts this session. */
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
