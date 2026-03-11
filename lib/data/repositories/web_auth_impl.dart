// Web implementation for Google Auth
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String> performWebGoogleAuth(Uri authUrl) {
  final completer = Completer<String>();
  StreamSubscription<html.MessageEvent>? subscription;

  subscription = html.window.onMessage.listen((html.MessageEvent event) {
    if (event.origin == 'http://localhost:4000') {
      final data = event.data;
      if (data is Map && data['type'] == 'googleAuthCallback') {
        final String? token = data['idToken'] as String?;
        if (token != null && token.isNotEmpty) {
          if (!completer.isCompleted) completer.complete(token);
        } else {
          if (!completer.isCompleted) {
            completer.completeError(Exception('ID token missing from Web popup callback.'));
          }
        }
        subscription?.cancel();
      }
    }
  });

  // Launch popup window natively without noopener to preserve window.opener
  html.window.open(authUrl.toString(), 'GoogleAuth', 'width=500,height=600');
  
  // Add a timeout just in case the user closes the popup
  Future.delayed(const Duration(minutes: 5), () {
    if (!completer.isCompleted) {
      subscription?.cancel();
      completer.completeError(Exception('Web Authentication timed out.'));
    }
  });

  return completer.future;
}
