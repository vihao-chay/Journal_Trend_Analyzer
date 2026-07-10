import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/firebase_options.dart';
import '../models/auth_user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<void> initialize();
  AuthUser? get currentUser;
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser?> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  firebase_auth.FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  @override
  AuthUser? get currentUser => _auth?.currentUser.toAuthUser();

  @override
  Stream<AuthUser?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream<AuthUser?>.value(null);
    }
    return auth.authStateChanges().map((user) => user.toAuthUser());
  }

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final options = AppFirebaseOptions.currentPlatform;
      if (Firebase.apps.isEmpty) {
        if (options == null) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(options: options);
        }
      }

      _auth ??= firebase_auth.FirebaseAuth.instance;
      await _googleSignIn.initialize(
        clientId: AppFirebaseOptions.googleClientId,
        serverClientId: AppFirebaseOptions.googleServerClientId,
      );

      _initialized = true;
    } on FirebaseException catch (exception) {
      throw AuthFailure(_firebaseMessage(exception));
    } on GoogleSignInException catch (exception) {
      throw AuthFailure(_googleMessage(exception));
    } catch (exception) {
      if (kDebugMode) {
        debugPrint('Firebase Auth init failed: $exception');
      }
      throw const AuthFailure(
        'Chưa tìm thấy cấu hình Firebase. Hãy cấu hình Firebase project trước khi đăng nhập Google.',
      );
    }
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailure(
        'Thiết bị này chưa hỗ trợ luồng đăng nhập Google trong ứng dụng.',
      );
    }

    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      return _signInFirebaseWithGoogle(account);
    } on FirebaseException catch (exception) {
      throw AuthFailure(_firebaseMessage(exception));
    } on GoogleSignInException catch (exception) {
      if (_isNoCredentialError(exception)) {
        return _signInWithFirebaseProvider();
      }
      throw AuthFailure(_googleMessage(exception));
    } catch (_) {
      throw const AuthFailure('Không thể đăng nhập bằng Google.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        if (_auth != null) _auth!.signOut(),
        if (_initialized) _googleSignIn.signOut(),
      ]);
    } on FirebaseException catch (exception) {
      throw AuthFailure(_firebaseMessage(exception));
    } catch (_) {
      throw const AuthFailure('Không thể đăng xuất. Vui lòng thử lại.');
    }
  }

  Future<AuthUser?> _signInFirebaseWithGoogle(
    GoogleSignInAccount account,
  ) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(
        'Google không trả về ID token. Hãy kiểm tra OAuth client trong Firebase.',
      );
    }

    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final userCredential = await _auth!.signInWithCredential(credential);
    return userCredential.user.toAuthUser();
  }

  Future<AuthUser?> _signInWithFirebaseProvider() async {
    try {
      final provider = firebase_auth.GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final userCredential = await _auth!.signInWithProvider(provider);
      return userCredential.user.toAuthUser();
    } on FirebaseException catch (exception) {
      throw AuthFailure(_firebaseMessage(exception));
    } catch (_) {
      throw const AuthFailure(
        'Google Sign-In không tìm thấy credential trên emulator này. Hãy thử emulator Google Play mới hoặc máy Android thật.',
      );
    }
  }

  bool _isNoCredentialError(GoogleSignInException exception) {
    final description = exception.description?.toLowerCase() ?? '';
    return exception.code == GoogleSignInExceptionCode.unknownError &&
        description.contains('no credential');
  }

  String _firebaseMessage(FirebaseException exception) {
    return switch (exception.code) {
      'channel-error' || 'core/no-app' || 'missing-app-config-values' =>
        'Firebase chưa được cấu hình cho ứng dụng này.',
      'network-request-failed' => 'Không có kết nối mạng để đăng nhập.',
      'account-exists-with-different-credential' =>
        'Email này đã liên kết với phương thức đăng nhập khác.',
      'invalid-credential' => 'Thông tin đăng nhập Google không hợp lệ.',
      'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
      _ => exception.message ?? 'Firebase Authentication gặp lỗi.',
    };
  }

  String _googleMessage(GoogleSignInException exception) {
    return switch (exception.code) {
      GoogleSignInExceptionCode.canceled => 'Bạn đã hủy đăng nhập Google.',
      GoogleSignInExceptionCode.interrupted =>
        'Đăng nhập Google bị gián đoạn. Vui lòng thử lại.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Google Sign-In hiện không khả dụng trên thiết bị này.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Cấu hình Google Sign-In chưa đúng trong Firebase.',
      _ => exception.description ?? 'Google Sign-In gặp lỗi.',
    };
  }
}

extension on firebase_auth.User? {
  AuthUser? toAuthUser() {
    final user = this;
    if (user == null) {
      return null;
    }
    return AuthUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}
