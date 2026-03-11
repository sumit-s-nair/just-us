import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/profile_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.selectedChatId,
    this.onChatSelected,
    this.showProfileAvatar = true,
  });

  final String? selectedChatId;
  final ValueChanged<String>? onChatSelected;
  final bool showProfileAvatar;

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
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {},
      tooltip: 'Start a new chat',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(56 * 0.28), // Standard FAB is 56x56
      ),
      child: const Icon(Icons.chat_bubble_outline_rounded),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final photoUrl = context.watch<AuthProvider>().user?.photoUrl;

    return AppBar(
      toolbarHeight: 72, // Give more breathing room from the OS title bar
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Text(
          'Chats',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
          ),
        ),
      ),
      actions: [
        if (showProfileAvatar)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                onTap: () => context.push('/profile-settings'),
                child: ProfileAvatar(photoUrl: photoUrl),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSearchBar(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(48 * 0.28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search chats & friends...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
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
      ),
    );
  }
}
