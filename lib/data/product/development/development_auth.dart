import '../models.dart';
import '../repositories.dart';

/// Explicit development story previews. No password database, email delivery,
/// Google request, protected credential or production session is created.
class DevelopmentAuthRepository implements AuthRepository {
  @override
  bool get isDevelopment => true;
  @override
  Future<Account> currentAccount(TokenPair tokens) async => throw const ProductFailure(FailureKind.unavailable);
  @override
  Future<void> register(String email, String password) async {}
  @override
  Future<void> resendVerification(String email) async {}
  @override
  Future<void> verifyEmail(String token, {required String email}) async {
    if (token != 'fixture-verify') throw const ProductFailure(FailureKind.validation, field: 'token');
  }

  @override
  Future<SessionGrant> login(String email, String password) async {
    if (email == 'unverified@example.invalid') throw const ProductFailure(FailureKind.unverified);
    final id = switch (email) {
      'reader@example.invalid' => 'development-reader',
      'other@example.invalid' => 'development-other',
      _ => throw const ProductFailure(FailureKind.unauthorized),
    };
    if (password != 'fixture-only') throw const ProductFailure(FailureKind.unauthorized);
    return SessionGrant(Account(id: id, email: email, emailVerified: true));
  }

  @override
  Future<SessionGrant> exchangeGoogleIdToken(String idToken) async =>
      throw const ProductFailure(FailureKind.unavailable);
  @override
  Future<void> requestRecovery(String email) async {}
  @override
  Future<void> confirmRecovery(String token, String password, {required String email}) async {
    if (token != 'fixture-reset') throw const ProductFailure(FailureKind.validation, field: 'token');
  }

  @override
  Future<TokenPair> refresh(TokenPair current) async => throw const ProductFailure(FailureKind.unavailable);
  @override
  Future<bool> logout(TokenPair? tokens) async => false;
}

class MemorySessionVault implements SessionVault {
  TokenPair? value;
  @override
  Future<TokenPair?> read() async => value;
  @override
  Future<void> replace(TokenPair tokens) async {
    value = tokens;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class MemoryAttemptStore implements AttemptStore {
  final _attempts = <String, CreateAttempt>{};
  @override
  Future<CreateAttempt?> read(String accountId) async => _attempts[accountId];
  @override
  Future<void> write(CreateAttempt attempt) async {
    _attempts[attempt.accountId] = attempt;
  }

  @override
  Future<void> clear(String accountId) async {
    _attempts.remove(accountId);
  }
}
