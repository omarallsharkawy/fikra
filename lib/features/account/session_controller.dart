import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/product/models.dart';
import '../../data/product/repositories.dart';

enum SessionStage {
  restoring,
  unauthenticated,
  awaitingVerification,
  authenticated,
  expired,
  recoveryRequest,
  recoverySent,
  recoveryConfirm,
}

class SessionController extends ChangeNotifier {
  SessionController(this.repository, this.vault, {this.clock = DateTime.now});
  final DateTime Function() clock;
  DateTime? retryAt;
  Timer? _retryWake;
  bool get coolingDown => retryAt != null && clock().isBefore(retryAt!);
  final AuthRepository repository;
  final SessionVault vault;
  SessionStage stage = SessionStage.restoring;
  Account? account;
  TokenPair? tokens;
  String email = '';
  bool busy = false;
  ProductFailure? failure;
  String? notice;
  int epoch = 0;
  Future<TokenPair>? _refreshing;
  Future<void> _vaultQueue = Future.value();
  bool _disposed = false;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _store(Future<void> Function() action) {
    final next = _vaultQueue.then((_) => action());
    _vaultQueue = next.catchError((_) {});
    return next;
  }

  Future<void> restore() async {
    final ticket = epoch;
    try {
      final grant = await repository.restore();
      if (_disposed || ticket != epoch) return;
      if (grant == null) {
        stage = SessionStage.unauthenticated;
      } else {
        await _install(grant, ticket);
      }
    } catch (error) {
      if (_disposed || ticket != epoch) return;
      failure = ProductFailure.from(error);
      stage = SessionStage.expired;
    }
    _emit();
  }

  void show(SessionStage next) {
    if (busy) return;
    stage = next;
    if (!coolingDown) failure = null;
    notice = null;
    _emit();
  }

  Future<void> _action(Future<void> Function(int ticket) work) async {
    if (busy || coolingDown) return;
    busy = true;
    failure = null;
    notice = null;
    _emit();
    final ticket = epoch;
    try {
      await work(ticket);
    } catch (error) {
      if (!_disposed && ticket == epoch) {
        failure = ProductFailure.from(error);
        if (failure!.kind == FailureKind.quota && failure!.retryAfter != null) {
          retryAt = clock().add(failure!.retryAfter!);
          _retryWake?.cancel();
          _retryWake = Timer(failure!.retryAfter!, _emit);
        }
        if (failure!.kind == FailureKind.unverified) stage = SessionStage.awaitingVerification;
      }
    } finally {
      if (!_disposed && ticket == epoch) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> register(String address, String password) => _action((ticket) async {
    email = address.trim().toLowerCase();
    await repository.register(email, password);
    if (ticket != epoch || _disposed) return;
    stage = SessionStage.awaitingVerification;
    notice = 'verificationRequested';
  });
  Future<void> resend() => _action((ticket) async {
    await repository.resendVerification(email);
    if (ticket == epoch && !_disposed) notice = 'verificationRequested';
  });
  Future<void> verify(String token) => _action((ticket) async {
    await repository.verifyEmail(token);
    if (ticket != epoch || _disposed) return;
    stage = SessionStage.unauthenticated;
    notice = 'verified';
  });
  Future<void> login(String address, String password) => _action((ticket) async {
    email = address.trim().toLowerCase();
    final grant = await repository.login(email, password);
    await _install(grant, ticket);
  });
  Future<void> google(String idToken) => _action((ticket) async {
    final grant = await repository.exchangeGoogleIdToken(idToken);
    await _install(grant, ticket);
  });
  Future<void> _install(SessionGrant grant, int ticket) async {
    if (ticket != epoch || _disposed) return;
    if (grant.tokens != null) {
      await _store(() async {
        if (ticket == epoch && !_disposed) await vault.replace(grant.tokens!);
      });
    }
    if (ticket != epoch || _disposed) return;
    account = grant.account;
    tokens = grant.tokens;
    stage = SessionStage.authenticated;
  }

  Future<void> recover(String address) => _action((ticket) async {
    email = address.trim().toLowerCase();
    await repository.requestRecovery(email);
    if (ticket != epoch || _disposed) return;
    stage = SessionStage.recoverySent;
    notice = 'recoveryRequested';
  });
  Future<void> confirmRecovery(String token, String password) async {
    await _action((ticket) async {
      await repository.confirmRecovery(token, password);
      if (ticket != epoch || _disposed) return;
      // Reset succeeds without creating a replacement session.
      await signOut();
      notice = 'reset';
      _emit();
    });
  }

  /// Used by a future protected transport: callers pass the access token used
  /// by the failed request and may retry the original operation only once.
  Future<TokenPair> refreshAfterUnauthorized(String failedAccess) {
    final current = tokens;
    if (current == null || stage != SessionStage.authenticated) {
      return Future.error(const ProductFailure(FailureKind.unauthorized));
    }
    if (current.access != failedAccess) return Future.value(current);
    if (_refreshing != null) return _refreshing!;
    final ticket = epoch;
    final job = _refresh(current, ticket);
    _refreshing = job;
    unawaited(
      job.then<void>(
        (_) {
          if (identical(_refreshing, job)) _refreshing = null;
        },
        onError: (Object _, StackTrace _) {
          if (identical(_refreshing, job)) _refreshing = null;
        },
      ),
    );
    return job;
  }

  Future<TokenPair> _refresh(TokenPair current, int ticket) async {
    try {
      final replacement = await repository.refresh(current);
      if (ticket != epoch || _disposed) throw const ProductFailure(FailureKind.unauthorized);
      await _store(() async {
        if (ticket == epoch && !_disposed) await vault.replace(replacement);
      });
      if (ticket != epoch || _disposed) throw const ProductFailure(FailureKind.unauthorized);
      tokens = replacement;
      _emit();
      return replacement;
    } catch (_) {
      // An uncertain refresh must never replay the possibly rotated token.
      if (ticket == epoch && !_disposed) await expire();
      rethrow;
    }
  }

  Future<void> expire() async {
    _retryWake?.cancel();
    retryAt = null;
    epoch++;
    account = null;
    tokens = null;
    busy = false;
    stage = SessionStage.expired;
    _refreshing = null;
    _emit();
    await _store(vault.clear);
  }

  Future<void> signOut() async {
    _retryWake?.cancel();
    retryAt = null;
    final old = tokens;
    epoch++;
    account = null;
    tokens = null;
    busy = false;
    stage = SessionStage.unauthenticated;
    failure = null;
    notice = 'localLogout';
    _refreshing = null;
    _emit();
    final ticket = epoch;
    await _store(vault.clear);
    try {
      final revoked = await repository.logout(old);
      if (ticket == epoch && !_disposed) {
        notice = revoked ? 'logout' : 'localLogout';
        _emit();
      }
    } catch (_) {
      /* Local cleanup is complete; server revocation is uncertain. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryWake?.cancel();
    epoch++;
    super.dispose();
  }
}
