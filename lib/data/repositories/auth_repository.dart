import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _gsi => _googleSignIn ??= GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: AppConfig.googleServerClientId,
      );

  /// Sign in with Google, then authenticate with our backend.
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _gsi.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    try {
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final deviceId = await _getDeviceId();

      final response = await apiClient.post('/api/auth/google', body: {
        'idToken': idToken,
        'deviceId': deviceId,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        await apiClient.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );

        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      throw Exception('Authentication failed: ${response.statusCode}');
    } catch (e) {
      // Revert Google sign-in if server-side authentication fails (ACID property)
      await _gsi.signOut();
      rethrow;
    }
  }

  /// Check if the user is currently authenticated.
  Future<UserModel?> getCurrentUser() async {
    if (!await apiClient.hasTokens) return null;

    try {
      final response = await apiClient.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sign out from both Google and the backend.
  Future<void> signOut() async {
    // 1. Server side logout with a very short timeout.
    // We await this so the ApiClient can read the current token from storage
    // before we delete it in step 3. The 1-second timeout ensures we don't
    // block the user if the server is unreachable.
    try {
      final refreshToken = await apiClient.refreshToken;
      if (refreshToken != null) {
        await apiClient
            .post('/api/auth/logout', body: {'refreshToken': refreshToken})
            .timeout(const Duration(seconds: 1));
      }
    } catch (_) {}

    // 2. Google Sign-Out (fast, local operation)
    try {
      await _gsi.signOut();
    } catch (_) {}

    // 3. Clear local tokens
    try {
      await apiClient.clearTokens();
    } catch (_) {}
  }

  Future<String> _getDeviceId() async {
    const storage = FlutterSecureStorage();
    var deviceId = await storage.read(key: 'device_id');
    if (deviceId == null) {
      final random = Random();
      deviceId = '${defaultTargetPlatform.name}_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000000)}';
      await storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }
}
