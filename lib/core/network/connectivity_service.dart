import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    // We only actively check network recovery when we know we're offline.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkRecovery());
  }

  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;

  void markOnline() {
    if (!_isOnline) {
      _isOnline = true;
      notifyListeners();
    }
  }

  void markOffline() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
  }

  Future<void> _checkRecovery() async {
    // If we're already online, our API calls will naturally catch any new drops.
    if (_isOnline) return;

    try {
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      // If we are testing locally, we can't reliably look up localhost on an emulator for internet connectivity.
      // So we fallback to a known host if developing locally, otherwise use the production backend host.
      final host = uri.host == '10.0.2.2' || uri.host == 'localhost' ? '8.8.8.8' : uri.host;

      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
          
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        markOnline();
      }
    } catch (_) {}
  }

  /// Force an immediate check (e.g. after user action).
  Future<void> checkNow() => _checkRecovery();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
