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

  /// Validate session with server (called in background).
  /// On network errors, keeps current state (user stays on home).
  /// Only logs out if server explicitly rejects the token.
  Future<void> checkAuth() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      // If user is null but no exception, tokens were cleared by the
      // API client (server rejected them). Only then mark unauthenticated.
      if (user == null && _status != AuthStatus.initial) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (_) {
      // Network error — silently keep current state.
      // User can still view cached messages offline.
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
