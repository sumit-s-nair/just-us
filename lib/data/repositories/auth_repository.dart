import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

const String _cachedUserKey = 'cached_user_model';

class AuthRepository {
  AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _gsi => _googleSignIn ??= GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: AppConfig.googleServerClientId, // Required for Web plugin
        serverClientId: AppConfig.googleServerClientId,
      );

  /// Sign in with Google, then authenticate with our backend.
  Future<UserModel> signInWithGoogle() async {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    String idToken;

    if (isDesktop) {
      idToken = await _performDesktopGoogleAuth();
    } else {
      final googleUser = await _gsi.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }
      idToken = googleAuth.idToken!;
    }

    try {
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

        final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        
        // Cache user model locally for fast startup
        const storage = FlutterSecureStorage();
        await storage.write(key: _cachedUserKey, value: jsonEncode(userModel.toJson()));

        // Also aggressively cache their profile image to disk
        if (userModel.photoUrl != null) {
          await _cacheProfileImage(userModel.photoUrl!);
        }

        return userModel;
      }

      throw Exception('Authentication failed: ${response.statusCode}');
    } catch (e) {
      if (!isDesktop) await _gsi.signOut();
      rethrow;
    }
  }

  /// Performs OAuth 2.0 Implicit Grant flow for Desktop by spinning up a local
  /// server and launching the default browser.
  Future<String> _performDesktopGoogleAuth() async {
    // 1. Start a local HTTP server to listen for the redirect on a fixed port
    // We use a fixed port (e.g. 3000) so you can whitelist exactly "http://localhost:3000" in Google Cloud Console.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4000);
    final port = server.port;

    // 2. Construct the Google OAuth URL targeting our local server
    final redirectUri = 'http://localhost:$port';
    // Note: Implicit flow normally returns token in url fragment (#), but some
    // server-side setups can be configured to use response_type=code or handle id_token via POST.
    // However, since we strictly need the id_token and don't want a full C++ plugin, 
    // we use response_type=id_token and response_mode=form_post to get it straight to our server.
    final authUrl = Uri.parse(
        'https://accounts.google.com/o/oauth2/v2/auth'
        '?client_id=${AppConfig.googleServerClientId}'
        '&redirect_uri=$redirectUri'
        '&response_type=id_token'
        '&scope=openid%20email%20profile'
        '&nonce=${Random().nextInt(100000)}'
        '&response_mode=form_post');

    // 3. Launch the browser
    if (!await launchUrl(authUrl)) {
      server.close();
      throw Exception('Could not launch browser for authentication.');
    }

    // 4. Wait for the redirect payload
    try {
      await for (var request in server) {
        if (request.method == 'POST') {
          // Parse the form body
          final body = await utf8.decoder.bind(request).join();
          final params = Uri.splitQueryString(body);

          final idToken = params['id_token'];

          // Send a success message to the browser
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write('''
            <html>
              <body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; background-color: #121212; color: #fff;">
                <div style="text-align: center;">
                  <h2>Authentication Successful!</h2>
                  <p>You can safely close this tab and return to the just us app.</p>
                </div>
              </body>
            </html>
            ''');
          await request.response.close();
          await server.close(force: true);

          if (idToken != null && idToken.isNotEmpty) {
            return idToken;
          } else {
            throw Exception('ID token missing from Google response.');
          }
        } else {
          request.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..write('Only POST allowed');
          await request.response.close();
        }
      }
    } catch (e) {
      server.close(force: true);
      throw Exception('Authentication cancelled or failed.');
    }
    
    server.close(force: true);
    throw Exception('Authentication timed out.');
  }

  /// Check if the user is currently authenticated.
  Future<UserModel?> getCurrentUser() async {
    if (!await apiClient.hasTokens) return null;

    UserModel? cachedUser = await getCurrentUserCachedOnly();

    try {
      final response = await apiClient.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final fetchedUser = UserModel.fromJson(data);
        
        // Update cache with fresh data
        const storage = FlutterSecureStorage();
        await storage.write(key: _cachedUserKey, value: jsonEncode(fetchedUser.toJson()));
        
        if (fetchedUser.photoUrl != null) {
          _cacheProfileImage(fetchedUser.photoUrl!); // Run without awaiting so it doesn't block startup
        }

        return fetchedUser;
      }
      return cachedUser; // Fallback to cache if request fails but we have tokens
    } catch (_) {
      return cachedUser; // Fallback to cache if network is down
    }
  }

  /// Get the user strictly from the local cache without network request.
  Future<UserModel?> getCurrentUserCachedOnly() async {
    try {
      const storage = FlutterSecureStorage();
      final cachedString = await storage.read(key: _cachedUserKey);
      if (cachedString != null) {
        return UserModel.fromJson(jsonDecode(cachedString) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
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

    // 3. Clear local tokens and cached user
    try {
      await apiClient.clearTokens();
      const storage = FlutterSecureStorage();
      await storage.delete(key: _cachedUserKey);
      
      // Delete cached image
      final file = await getProfileImageFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
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

  /// Helper to get the absolute file reference where the profile image should live
  Future<File?> getProfileImageFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/cached_profile_pic.jpg');
    } catch (_) {
      return null;
    }
  }

  /// Downloads and caches the profile picture byte stream to local storage
  Future<void> _cacheProfileImage(String url) async {
    try {
      final file = await getProfileImageFile();
      if (file == null) return;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
  }
}

