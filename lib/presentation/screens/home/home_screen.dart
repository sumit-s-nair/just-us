import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';
import '../../widgets/offline_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.maxContentWidth,
                  ),
                  child: _buildEmptyState(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Start a new chat',
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const LogoWidget(
              size: AppTheme.logoSmall,
              showText: false,
            ),
            const SizedBox(width: 10),
            Text(
              'just us',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          tooltip: 'Sign out',
          onPressed: () => _signOut(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _signOut(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Sign out?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'You will need to sign in again to access your chats.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.signOut();
              router.go('/login');
            },
            child: Text(
              'Sign out',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LogoWidget(
          size: AppTheme.logoLarge,
          showText: false,
        ),
        const SizedBox(height: 16),
        Text(
          'just us, for now',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w300,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
