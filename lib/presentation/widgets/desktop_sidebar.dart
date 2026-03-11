import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import 'profile_avatar.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.watch<AuthProvider>().user?.photoUrl;

    return Container(
      width: 64, // Fixed narrow width for the rail
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Navigation Icons (Chats)
          _SidebarIcon(
            icon: Icons.chat_bubble_rounded,
            isSelected: true,
            onTap: () {}, // Already on chats
          ),
          
          const Spacer(),
          
          // Settings / Profile
          GestureDetector(
            onTap: () => context.push('/profile-settings'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ProfileAvatar(photoUrl: photoUrl, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealMain.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(40 * 0.28),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.tealMain : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
