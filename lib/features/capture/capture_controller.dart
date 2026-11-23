import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/product/models.dart';
import '../../data/product/repositories.dart';
import 'local_documents.dart';

abstract interface class CaptureDevice {
  Future<void> start();
  Future<RecordedClip?> stop(Duration duration);
  Future<void> cancel();
  Future<void> dispose();
}

enum CaptureState { idle, starting, recording, stopping, recorded, transcribing, review }

class CaptureController extends ChangeNotifier {
  CaptureController(this.device, this.repository, {this.clock = DateTime.now, this.documents, this.onUnauthorized});
  final CaptureDevice device;
  final VoidCallback? onUnauthorized;
  DateTime? retryAt;
  Timer? _retryWake;
  bool get coolingDown => retryAt != null && clock().isBefore(retryAt!);
  final LocalDocuments? documents;
  List<LocalDocument> localPdfs = const [];
  bool pickingPdf = false;
  final KnowledgeRepository repository;
  final DateTime Function() clock;
  static const maximum = Duration(seconds: 60);
  String? accountId;
  CaptureState state = CaptureState.idle;
  Duration elapsed = Duration.zero;
  RecordedClip? clip;
  String transcript = '';
  ProductFailure? failure;
  int _epoch = 0;
  bool _disposed = false;
  Timer? _tick, _limit;
  DateTime? _started;
  Future<void> _cleanup = Future.value();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  bool _valid(int ticket) => !_disposed && ticket == _epoch && accountId != null;
  bool get active =>
      state == CaptureState.starting ||
      state == CaptureState.recording ||
      state == CaptureState.stopping ||
      state == CaptureState.transcribing;
  void setAccount(String? id) {
    if (id != accountId) {
      _retryWake?.cancel();
      retryAt = null;
    }
    _epoch++;
    _timersOff();
    _cleanup = _cleanup.then((_) => device.cancel()).catchError((_) {});
    localPdfs = const [];
    pickingPdf = false;
    accountId = id;
    clip = null;
    transcript = '';
    failure = null;
    elapsed = Duration.zero;
    state = CaptureState.idle;
    _emit();
  }

  Future<void> start() async {
    if (accountId == null || active) return;
    final ticket = ++_epoch;
    state = CaptureState.starting;
    failure = null;
    clip = null;
    transcript = '';
    _emit();
    try {
      await _cleanup;
      if (!_valid(ticket)) return;
      await device.cancel();
      if (!_valid(ticket)) return;
      await device.start();
      // Account reset/disposal owns cleanup and gates the next start.
      if (!_valid(ticket)) return;
      _started = clock();
      elapsed = Duration.zero;
      state = CaptureState.recording;
      _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
        elapsed = clock().difference(_started!);
        if (elapsed > maximum) elapsed = maximum;
        _emit();
      });
      _limit = Timer(maximum, () {
        elapsed = maximum;
        unawaited(stop());
      });
    } catch (error) {
      if (_valid(ticket)) {
        try {
          await device.cancel();
        } catch (_) {
          /* Preserve the original failure. */
        }
        if (!_valid(ticket)) return;
        failure = ProductFailure.from(error);
        state = CaptureState.idle;
      }
    } finally {
      if (_valid(ticket)) _emit();
    }
  }

  Future<void> stop() async {
    if (state != CaptureState.recording) return;
    final ticket = _epoch;
    _timersOff();
    state = CaptureState.stopping;
    _emit();
    try {
      final result = await device.stop(elapsed);
      if (!_valid(ticket)) return;
      clip = result;
      state = result == null ? CaptureState.idle : CaptureState.recorded;
      if (result == null) failure = const ProductFailure(FailureKind.unavailable);
    } catch (error) {
      if (_valid(ticket)) {
        failure = ProductFailure.from(error);
        state = CaptureState.idle;
      }
    } finally {
      if (_valid(ticket)) _emit();
    }
  }

  Future<void> cancel() async {
    final account = accountId;
    setAccount(account);
    await _cleanup;
  }

  Future<void> transcribe() async {
    final account = accountId, recording = clip, ticket = _epoch;
    if (account == null || recording == null || active || coolingDown) return;
    state = CaptureState.transcribing;
    failure = null;
    _emit();
    try {
      final text = await repository.transcribe(account, recording);
      if (!_valid(ticket)) return;
      transcript = text;
      state = CaptureState.review;
    } catch (error) {
      if (_valid(ticket)) {
        failure = ProductFailure.from(error);
        if (failure!.kind == FailureKind.quota && failure!.retryAfter != null) {
          retryAt = clock().add(failure!.retryAfter!);
          _retryWake?.cancel();
          _retryWake = Timer(failure!.retryAfter!, _emit);
        }
        state = CaptureState.recorded;
        if (failure!.kind == FailureKind.unauthorized) onUnauthorized?.call();
      }
    } finally {
      if (_valid(ticket)) _emit();
    }
  }

  Future<void> pickPdf() async {
    if (accountId == null || pickingPdf || active) return;
    final ticket = _epoch;
    pickingPdf = true;
    failure = null;
    _emit();
    try {
      final document = await documents?.pickPdf();
      if (_valid(ticket) && document != null) localPdfs = [...localPdfs, document];
    } catch (error) {
      if (_valid(ticket)) failure = ProductFailure.from(error);
    } finally {
      if (_valid(ticket)) {
        pickingPdf = false;
        _emit();
      }
    }
  }

  Future<void> openPdf(LocalDocument document) async {
    final ticket = _epoch;
    try {
      await documents?.open(document);
    } catch (error) {
      if (_valid(ticket)) {
        failure = ProductFailure.from(error);
        _emit();
      }
    }
  }

  void editTranscript(String text) {
    transcript = text;
    _emit();
  }

  void background() {
    if (state == CaptureState.starting) {
      unawaited(cancel());
    } else if (state == CaptureState.recording) {
      unawaited(stop());
    }
  }

  void _timersOff() {
    _tick?.cancel();
    _limit?.cancel();
    _tick = null;
    _limit = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _retryWake?.cancel();
    _epoch++;
    _timersOff();
    unawaited(_cleanup.then((_) => device.dispose()));
    super.dispose();
  }
}
