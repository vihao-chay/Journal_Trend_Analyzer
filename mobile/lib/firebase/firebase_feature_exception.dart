class FirebaseFeatureException implements Exception {
  const FirebaseFeatureException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
