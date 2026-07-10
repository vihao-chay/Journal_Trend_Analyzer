import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    bool autoInitialize = true,
    AuthUser? initialUser,
  }) : _authService = authService ?? FirebaseAuthService(),
       user = initialUser,
       isInitializing = autoInitialize {
    if (autoInitialize) {
      initialize();
    }
  }

  final AuthService _authService;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthUser? user;
  bool isInitializing;
  bool isSigningIn = false;
  bool isSigningOut = false;
  String? errorMessage;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    isInitializing = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.initialize();
      user = _authService.currentUser;
      await _authSubscription?.cancel();
      _authSubscription = _authService.authStateChanges.listen((nextUser) {
        user = nextUser;
        errorMessage = null;
        notifyListeners();
      });
    } on AuthFailure catch (exception) {
      errorMessage = exception.message;
    } catch (_) {
      errorMessage = 'Không thể khởi tạo Firebase Authentication.';
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    isSigningIn = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = await _authService.signInWithGoogle();
    } on AuthFailure catch (exception) {
      errorMessage = exception.message;
    } catch (_) {
      errorMessage = 'Không thể đăng nhập bằng Google.';
    } finally {
      isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    isSigningOut = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      user = null;
    } on AuthFailure catch (exception) {
      errorMessage = exception.message;
    } catch (_) {
      errorMessage = 'Không thể đăng xuất. Vui lòng thử lại.';
    } finally {
      isSigningOut = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) {
      return;
    }
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
