import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/network/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

/// A thin banner displayed at the top of the screen when offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: Colors.orange.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                'No internet connection',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
