import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photoUrl, this.size = 40});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return FutureBuilder<File?>(
      future: authProvider.authRepository.getProfileImageFile(),
      builder: (context, snapshot) {
        final File? file = snapshot.data;
        final bool hasLocalFile = file != null && file.existsSync();

        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(color: AppColors.tealDim),
          ),
          clipBehavior: Clip.hardEdge,
          child: _buildImageContent(hasLocalFile, file),
        );
      },
    );
  }

  Widget _buildImageContent(bool hasLocalFile, File? file) {
    if (hasLocalFile) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Icon(
      Icons.person_rounded,
      color: AppColors.tealMain,
      size: size * 0.6,
    );
  }
}
