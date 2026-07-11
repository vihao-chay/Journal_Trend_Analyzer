class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  String get nameOrEmail {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail;
    }
    return 'Người dùng OpenAlex';
  }

  String get initials {
    final source = nameOrEmail.trim();
    if (source.isEmpty) {
      return 'U';
    }
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }
}
