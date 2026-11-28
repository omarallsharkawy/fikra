import 'package:flutter/foundation.dart';

import '../../data/ids.dart';
import '../../data/product/local_ui_store.dart';
import '../../data/product/models.dart';

class LocalTag {
  const LocalTag(this.id, this.label, this.color);
  final String id, label;

  /// A semantic palette index, independent of theme or language.
  final int color;
}

/// User-created categories are device-owned; they never become API concepts.
class LocalTagsController extends ChangeNotifier {
  LocalTagsController(this.store);
  final LocalUiStore store;
  String? accountId;
  List<LocalTag> tags = const [];
  Map<String, Set<String>> assignments = {};
  bool loading = false, busy = false;
  ProductFailure? failure;
  int _epoch = 0;
  bool _disposed = false;
  List<LocalTag> forNote(String id) => tags.where((t) => assignments[id]?.contains(t.id) ?? false).toList();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  bool _valid(int ticket) => !_disposed && ticket == _epoch;
  Future<void> bind(String? id) async {
    final ticket = ++_epoch;
    accountId = id;
    tags = const [];
    assignments = {};
    failure = null;
    busy = false;
    loading = id != null;
    _emit();
    if (id == null) return;
    try {
      final r = await store.read('account:$id');
      if (!_valid(ticket)) return;
      final raw = r['tags'];
      if (raw is List) {
        tags = List.unmodifiable(
          raw
              .whereType<Map>()
              .where((v) => v['id'] is String && v['label'] is String)
              .map(
                (v) =>
                    LocalTag(v['id'] as String, v['label'] as String, (v['color'] as num?)?.toInt().clamp(0, 3) ?? 0),
              ),
        );
      }
      final values = r['note_tags'];
      if (values is Map) {
        assignments = {
          for (final e in values.entries)
            if (e.key is String && e.value is List) e.key as String: (e.value as List).whereType<String>().toSet(),
        };
      }
    } catch (_) {
      if (_valid(ticket)) failure = const ProductFailure(FailureKind.unavailable);
    } finally {
      if (_valid(ticket)) {
        loading = false;
        _emit();
      }
    }
  }

  Future<bool> _write(List<LocalTag> nextTags, Map<String, Set<String>> nextAssignments) async {
    final id = accountId, ticket = _epoch;
    if (id == null || busy || loading) return false;
    busy = true;
    failure = null;
    _emit();
    try {
      await store.update('account:$id', (r) {
        r['tags'] = [
          for (final t in nextTags) {'id': t.id, 'label': t.label, 'color': t.color},
        ];
        r['note_tags'] = {for (final e in nextAssignments.entries) e.key: e.value.toList()};
      });
      if (!_valid(ticket)) return false;
      tags = List.unmodifiable(nextTags);
      assignments = nextAssignments;
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

  Future<LocalTag?> create(String label, {int color = 0}) async {
    final clean = label.trim();
    if (clean.isEmpty || busy || loading) return null;
    final existing = tags.where((t) => t.label.toLowerCase() == clean.toLowerCase()).firstOrNull;
    if (existing != null) return existing;
    final tag = LocalTag(newId(), clean, color.clamp(0, 3));
    return await _write([...tags, tag], {...assignments}) ? tag : null;
  }

  Future<bool> rename(String id, String label, {int? color}) async {
    if (label.trim().isEmpty || !tags.any((t) => t.id == id)) return false;
    if (tags.any((t) => t.id != id && t.label.toLowerCase() == label.trim().toLowerCase())) return false;
    return _write(
      [
        for (final t in tags)
          if (t.id == id) LocalTag(id, label.trim(), color?.clamp(0, 3) ?? t.color) else t,
      ],
      {...assignments},
    );
  }

  Future<bool> assign(String noteId, Set<String> values) =>
      _write(tags, {...assignments, noteId: values.intersection(tags.map((t) => t.id).toSet())});
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
