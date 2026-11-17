import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import 'providers.dart';

class _AddRecordingLive extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

/// True while a live voice recording is actively running on the Add tab.
final addRecordingLiveProvider = NotifierProvider<_AddRecordingLive, bool>(_AddRecordingLive.new);

class RecordingActivity extends Notifier<bool> {
  Object? _owner;
  bool _fromAdd = false;
  late ValueNotifier<Duration> _elapsed;

  ValueListenable<Duration> get elapsed => _elapsed;

  @override
  bool build() {
    final notifier = ValueNotifier<Duration>(Duration.zero);
    _elapsed = notifier;
    ref.onDispose(notifier.dispose);
    return false;
  }

  bool claim(Object owner, {bool fromAdd = false}) {
    if (_owner != null) return false;
    _owner = owner;
    _fromAdd = fromAdd;
    _elapsed.value = Duration.zero;
    state = true;
    return true;
  }

  void markLive(Object owner) {
    if (!identical(_owner, owner)) return;
    if (_fromAdd && ref.mounted) {
      ref.read(addRecordingLiveProvider.notifier).set(true);
    }
  }

  void markStopping(Object owner) {
    if (!identical(_owner, owner)) return;
    if (ref.mounted) {
      ref.read(addRecordingLiveProvider.notifier).set(false);
    }
  }

  void setElapsed(Object owner, Duration value) {
    if (!identical(_owner, owner)) return;
    if (_elapsed.value != value) _elapsed.value = value;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _fromAdd = false;
    if (ref.mounted) {
      _elapsed.value = Duration.zero;
      ref.read(addRecordingLiveProvider.notifier).set(false);
      state = false;
    }
  }
}

final recordingActiveProvider = NotifierProvider<RecordingActivity, bool>(RecordingActivity.new);

/// Note ID of the saved voice attachment currently being transcribed in the
/// background, or null when no transcription job is running.
final activeTranscriptionNoteIdProvider = StreamProvider.autoDispose<String?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.noteAttachments)
        ..where((a) => a.transcriptionStatus.equals(TranscriptionStatus.running.name))
        ..orderBy([(a) => OrderingTerm.asc(a.transcriptionOrder), (a) => OrderingTerm.asc(a.createdAt)])
        ..limit(1))
      .watchSingleOrNull()
      .map((a) => a?.noteId);
});
