import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' hide GoogleIdentity;

import '../../data/product/models.dart';
import 'google_identity.dart';

// Public Web application identifier confirmed by the owner. No client secret.
const googleServerClientId = String.fromEnvironment(
  'FIKRA_GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '109535867594-0gok833v4j10mtedhee5146g8r8dcgtn.apps.googleusercontent.com',
);
final googleIdentityProvider = Provider<GoogleIdentity>((ref) => NativeGoogleIdentity());

class NativeGoogleIdentity implements GoogleIdentity {
  NativeGoogleIdentity({this.serverClientId = googleServerClientId});
  final String serverClientId;
  static Future<void>? _initialization;
  @override
  bool get available => !kIsWeb && defaultTargetPlatform == TargetPlatform.android && serverClientId.isNotEmpty;
  @override
  Future<GoogleCredential?> authenticate() async {
    if (!available) throw const ProductFailure(FailureKind.unavailable, field: 'google');
    try {
      final sdk = GoogleSignIn.instance;
      try {
        await (_initialization ??= sdk.initialize(serverClientId: serverClientId));
      } catch (_) {
        _initialization = null;
        rethrow;
      }
      final account = await sdk.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const ProductFailure(FailureKind.unavailable, field: 'google');
      }
      return GoogleCredential(token, name: account.displayName);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      // SDK/provider diagnostics can include identifiers; expose only localized UI.
      throw const ProductFailure(FailureKind.unavailable, field: 'google');
    } on ProductFailure {
      rethrow;
    } catch (_) {
      throw const ProductFailure(FailureKind.unavailable, field: 'google');
    }
  }
}
