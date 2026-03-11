import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum LogoLayout { horizontal, vertical }

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.size = 120,
    this.showText = true,
    this.layout = LogoLayout.vertical,
    this.textColor = AppColors.textPrimary,
  });

  final double size;
  final bool showText;
  final LogoLayout layout;
  final Color textColor;

  double get _borderRadius => size * 0.28;
  double get _strokeWidth => size * 0.12;
  double get _fontSize => size * 0.28;
  double get _gap => size * 0.12;

  @override
  Widget build(BuildContext context) {
    final square = _buildSquare();

    if (!showText) return square;

    final text = Text(
      'just us',
      style: GoogleFonts.inter(
        fontSize: _fontSize,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: -0.3,
        height: 1.2,
      ),
    );

    return layout == LogoLayout.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [square, SizedBox(height: _gap), text],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [square, SizedBox(width: _gap), text],
          );
  }

  Widget _buildSquare() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: AppColors.tealMain,
          width: _strokeWidth,
        ),
      ),
    );
  }
}
