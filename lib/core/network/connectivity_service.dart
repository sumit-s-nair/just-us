import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      _setOnline(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (_) {
      _setOnline(false);
    }
  }

  void _setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      notifyListeners();
    }
  }

  /// Force an immediate check (e.g. after user action).
  Future<void> checkNow() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
