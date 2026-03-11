import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';

/// Splash screen — shown only briefly while checking local token state.
/// Routes instantly based on stored tokens (no network call).
/// Server validation happens in the background from the home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeImmediately();
    });
  }

  Future<void> _routeImmediately() async {
    final apiClient = context.read<ApiClient>();
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);

    final hasTokens = await apiClient.hasTokens;

    if (!mounted) return;

    if (hasTokens) {
      // Tokens exist locally — go straight to home.
      // Validate session silently in the background.
      router.go('/home');
      auth.checkAuth();
    } else {
      router.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxAuthWidth),
          child: const LogoWidget(
            size: AppTheme.logoLarge,
            showText: true,
            layout: LogoLayout.vertical,
          ),
        ),
      ),
    );
  }
}
