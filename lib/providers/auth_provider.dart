import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authRepository});

  final AuthRepository authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Validate session with server.
  /// First emits the cached user instantly. Then quietly updates from network.
  /// On network errors, keeps current state.
  /// Only fully logs out if server explicitly rejects the token.
  Future<void> checkAuth() async {
    try {
      // 1. Immediately emit the localized cached user if available
      final cachedUser = await authRepository.getCurrentUserCachedOnly();
      if (cachedUser != null) {
        _user = cachedUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        // If there's no cache, we should at least signify we are loading
        _status = AuthStatus.loading;
        notifyListeners();
      }

      // 2. Refresh/Verify with the backend
      final freshUser = await authRepository.getCurrentUser();
      
      if (freshUser != null) {
        _user = freshUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }

      // 3. If user is null but no exception, tokens were explicitly cleared by the
      // API client (e.g. server rejected them with 401).
      if (freshUser == null && _status != AuthStatus.initial) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (_) {
      // Network error — silently keep the cached user state.
    }
  }

  /// Sign in with Google.
  Future<void> signIn() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await authRepository.signInWithGoogle();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  /// Sign out.
  Future<void> signOut() async {
    await authRepository.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
