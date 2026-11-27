import '../models.dart';
import '../repositories.dart';
import 'api_client.dart';
import 'api_models.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.api, {this.clock = DateTime.now});
  final ApiClient api;
  final DateTime Function() clock;
  @override
  bool get isDevelopment => false;
  @override
  Future<Account> currentAccount(TokenPair tokens) async =>
      accountFromJson(await api.request('GET', '/v1/auth/me', accessToken: tokens.access));
  @override
  Future<void> register(String email, String password) async {
    await api.request('POST', '/v1/auth/register/otp', json: {'email': email, 'password': password});
  }

  @override
  Future<void> verifyEmail(String token, {required String email}) async {
    await _code('/v1/auth/verify-email/otp', {'email': email, 'code': token});
  }

  @override
  Future<void> resendVerification(String email) async {
    await api.request('POST', '/v1/auth/resend-verification/otp', json: {'email': email});
  }

  Future<void> _code(String path, Object payload) async {
    try {
      await api.request('POST', path, json: payload);
    } on ProductFailure catch (error) {
      if (error.kind == FailureKind.validation && error.field == null) {
        throw const ProductFailure(FailureKind.validation, field: 'code');
      }
      rethrow;
    }
  }

  Future<SessionGrant> _grant(String path, Object payload) async {
    final pair = tokensFromJson(await api.request('POST', path, json: payload), clock());
    return SessionGrant(await currentAccount(pair), tokens: pair);
  }

  @override
  Future<SessionGrant> login(String email, String password) =>
      _grant('/v1/auth/login', {'email': email, 'password': password});
  @override
  Future<SessionGrant> exchangeGoogleIdToken(String idToken) => _grant('/v1/auth/google', {'id_token': idToken});
  @override
  Future<void> requestRecovery(String email) async {
    await api.request('POST', '/v1/auth/password-reset/otp/request', json: {'email': email});
  }

  @override
  Future<void> confirmRecovery(String token, String password, {required String email}) async {
    await _code('/v1/auth/password-reset/otp/confirm', {'email': email, 'code': token, 'new_password': password});
  }

  @override
  Future<TokenPair> refresh(TokenPair current) async =>
      tokensFromJson(await api.request('POST', '/v1/auth/refresh', json: {'refresh_token': current.refresh}), clock());
  @override
  Future<bool> logout(TokenPair? tokens) async {
    if (tokens == null) return true;
    await api.request('POST', '/v1/auth/logout', json: {'refresh_token': tokens.refresh});
    return true;
  }
}
