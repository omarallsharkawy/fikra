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
  int _noticeSeq = 0;
  Future<TokenPair>? _refreshing;
  Future<void> _vaultQueue = Future.value();
  bool _disposed = false;
  bool _restoring = false;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _store(Future<void> Function() action) {
    final next = _vaultQueue.then((_) => action());
    _vaultQueue = next.catchError((_) {});
    return next;
  }

  Future<void> restore() async {
    if (_restoring) return;
    _restoring = true;
    final ticket = epoch;
    if (failure != null) {
      failure = null;
      _emit();
    }
    var hasSafeVaultPair = false;
    try {
      var pair = await vault.read();
      if (_disposed || ticket != epoch) return;
      if (pair == null) {
        stage = SessionStage.unauthenticated;
      } else {
        hasSafeVaultPair = true;
        var rotated = false;
        if (!pair.expiresAt.isAfter(clock().add(const Duration(seconds: 30)))) {
          hasSafeVaultPair = false;
          pair = await _rotate(pair, ticket);
          hasSafeVaultPair = true;
          rotated = true;
        }
        Account account;
        try {
          account = await repository.currentAccount(pair);
        } on ProductFailure catch (error) {
          if (error.kind != FailureKind.unauthorized || rotated) rethrow;
          hasSafeVaultPair = false;
          pair = await _rotate(pair, ticket);
          hasSafeVaultPair = true;
          account = await repository.currentAccount(pair);
        }
        await _install(SessionGrant(account, tokens: pair), ticket);
      }
    } catch (error) {
      if (_disposed || ticket != epoch) return;
      final problem = ProductFailure.from(error);
      final transient =
          problem.kind == FailureKind.uncertain ||
          problem.kind == FailureKind.unavailable ||
          problem.kind == FailureKind.quota;
      failure = problem;
      if (hasSafeVaultPair && transient) {
        // Keep persisted tokens intact on offline/transient failures so the
        // user can retry without losing their session.
        stage = SessionStage.restoring;
        return;
      }
      stage = SessionStage.expired;
      try {
        await _store(() async {
          if (ticket == epoch && !_disposed) await vault.clear();
        });
      } catch (_) {
        failure = const ProductFailure(FailureKind.unavailable);
      }
    } finally {
      _restoring = false;
      if (!_disposed && ticket == epoch) _emit();
    }
  }

  void show(SessionStage next) {
    if (busy) return;
    _noticeSeq++;
    stage = next;
    if (!coolingDown) failure = null;
    notice = null;
    _emit();
  }

  Future<void> _action(Future<void> Function(int ticket) work) async {
    if (busy || coolingDown) return;
    _noticeSeq++;
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
    await repository.verifyEmail(token, email: email);
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
    _noticeSeq++;
    account = grant.account;
    tokens = grant.tokens;
    stage = SessionStage.authenticated;
    failure = null;
    notice = null;
    busy = false;
    epoch++;
    _emit();
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
      await repository.confirmRecovery(token, password, email: email);
      if (ticket != epoch || _disposed) return;
      // Reset succeeds without creating a replacement session; fence any active
      // session/refresh/restore while keeping busy=true until cleanup completes.
      final old = tokens;
      final hadActiveSession = old != null || account != null || _restoring;
      _noticeSeq++;
      _retryWake?.cancel();
      retryAt = null;
      if (hadActiveSession) epoch++;
      account = null;
      tokens = null;
      _refreshing = null;
      stage = SessionStage.unauthenticated;
      failure = null;
      notice = 'reset';
      try {
        await _store(vault.clear);
      } catch (_) {
        /* Best-effort local vault clear after password reset. */
      }
      if (old != null) unawaited(repository.logout(old).catchError((Object _) => false));
      if (hadActiveSession && !_disposed) {
        busy = false;
        _emit();
      }
    });
  }

  /// Used by the protected transport: callers pass the access token used
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

  Future<TokenPair> _rotate(TokenPair current, int ticket) async {
    // Remove the old rotating pair BEFORE sending: a killed process must not
    // replay a refresh token whose server-side rotation may have committed.
    await _store(() async {
      if (ticket == epoch && !_disposed) await vault.clear();
    });
    if (ticket != epoch || _disposed) throw const ProductFailure(FailureKind.unauthorized);
    final replacement = await repository.refresh(current);
    if (ticket != epoch || _disposed) throw const ProductFailure(FailureKind.unauthorized);
    await _store(() async {
      if (ticket == epoch && !_disposed) await vault.replace(replacement);
    });
    if (ticket != epoch || _disposed) throw const ProductFailure(FailureKind.unauthorized);
    return replacement;
  }

  Future<TokenPair> _refresh(TokenPair current, int ticket) async {
    try {
      final replacement = await _rotate(current, ticket);
      tokens = replacement;
      _emit();
      return replacement;
    } catch (error) {
      // An uncertain refresh must never replay the possibly rotated token.
      if (ticket == epoch && !_disposed) await expire(reason: ProductFailure.from(error));
      rethrow;
    }
  }

  Future<void> expire({ProductFailure? reason}) async {
    _retryWake?.cancel();
    retryAt = null;
    _noticeSeq++;
    epoch++;
    account = null;
    tokens = null;
    busy = false;
    stage = SessionStage.expired;
    notice = null;
    if (reason != null) failure = reason;
    _refreshing = null;
    _emit();
    try {
      await _store(vault.clear);
    } catch (_) {
      failure = const ProductFailure(FailureKind.unavailable);
      _emit();
    }
  }

  Future<void> signOut() async {
    _retryWake?.cancel();
    retryAt = null;
    final old = tokens;
    final signOutSeq = ++_noticeSeq;
    epoch++;
    account = null;
    tokens = null;
    busy = false;
    stage = SessionStage.unauthenticated;
    failure = null;
    notice = 'localLogout';
    _refreshing = null;
    _emit();
    var cleared = true;
    try {
      await _store(vault.clear);
    } catch (_) {
      cleared = false;
    }
    if (!cleared && signOutSeq == _noticeSeq && !_disposed) {
      notice = null;
      failure = const ProductFailure(FailureKind.unavailable);
      _emit();
    }
    try {
      final revoked = await repository.logout(old);
      if (signOutSeq == _noticeSeq && !_disposed) {
        notice = revoked
            ? 'logout'
            : cleared
            ? 'localLogout'
            : null;
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
