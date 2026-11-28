/// A short-lived native identity assertion, never persisted or logged.
class GoogleCredential {
  const GoogleCredential(this.idToken, {this.name});
  final String idToken;
  final String? name;
}

abstract interface class GoogleIdentity {
  bool get available;

  /// A canceled account picker returns null and does not alter the FIKRAH session.
  Future<GoogleCredential?> authenticate();
}
