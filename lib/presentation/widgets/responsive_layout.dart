import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/theme/app_colors.dart';

/// A wrapper that dynamically renders either a standard mobile layout 
/// or a split master-detail layout based on available screen width.
/// On desktop, the divider can be dragged to resize the split.
class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    required this.masterLayout,
    required this.detailLayout,
    this.breakpoint = 800.0,
    this.initialMasterWidth = 350.0,
    this.minMasterWidth = 250.0,
    this.maxMasterWidth = 600.0,
    this.sideNavigationLayout,
  });

  /// The standard layout shown on screens narrower than `breakpoint`
  final Widget mobileLayout;

  /// Optional far-left navigation rail (e.g. WhatsApp Web sidebar)
  final Widget? sideNavigationLayout;

  /// The left-hand sidebar shown on large screens
  final Widget masterLayout;

  /// The right-hand content area shown on large screens
  final Widget detailLayout;

  /// The pixel width at which the layout splits
  final double breakpoint;

  /// The default width of the left-hand sidebar if not previously saved
  final double initialMasterWidth;

  /// Minimum width of the left-hand sidebar
  final double minMasterWidth;

  /// Maximum width of the left-hand sidebar
  final double maxMasterWidth;

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  static const _storageKey = 'responsive_master_width';
  final _storage = const FlutterSecureStorage();

  late double _currentWidth;
  bool _isDragging = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentWidth = widget.initialMasterWidth;
    _loadSavedWidth();
  }

  Future<void> _loadSavedWidth() async {
    try {
      final savedStr = await _storage.read(key: _storageKey);
      if (savedStr != null) {
        final savedWidth = double.tryParse(savedStr);
        if (savedWidth != null && savedWidth >= widget.minMasterWidth && savedWidth <= widget.maxMasterWidth) {
          if (mounted) {
            setState(() {
              _currentWidth = savedWidth;
            });
          }
        }
      }
    } catch (_) {
      // Ignore storage errors, default to initial
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWidth(double width) async {
    try {
      await _storage.write(key: _storageKey, value: width.toString());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.breakpoint) {
          return widget.mobileLayout;
        }

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
          ); // Avoid flicker by rendering blank background for an instant
        }

        // Clamp width so that detail pane doesn't vanish on small desktop resolutions
        final maxAllowed = constraints.maxWidth - 300.0; // detail should at least be 300px wide
        final clampedMax = maxAllowed < widget.maxMasterWidth ? maxAllowed : widget.maxMasterWidth;
        final currentClamped = _currentWidth > clampedMax ? clampedMax : _currentWidth;
        final finalWidth = currentClamped < widget.minMasterWidth ? widget.minMasterWidth : currentClamped;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Far Left Sidebar (if provided)
              if (widget.sideNavigationLayout != null) ...[
                widget.sideNavigationLayout!,
                Container(
                  width: 1,
                  color: AppColors.textSecondary.withOpacity(0.15),
                ),
              ],

              // Master List (Left Side)
              SizedBox(
                width: finalWidth,
                child: widget.masterLayout,
              ),

              // Draggable Divider
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanDown: (_) => setState(() => _isDragging = true),
                  onPanEnd: (_) {
                    setState(() => _isDragging = false);
                    _saveWidth(_currentWidth);
                  },
                  onPanCancel: () {
                    setState(() => _isDragging = false);
                    _saveWidth(_currentWidth);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      var newWidth = _currentWidth + details.delta.dx;
                      
                      // Enforce widget constraints
                      if (newWidth < widget.minMasterWidth) {
                        newWidth = widget.minMasterWidth;
                      } else if (newWidth > widget.maxMasterWidth) {
                        newWidth = widget.maxMasterWidth;
                      }

                      // Enforce dynamic container constraints
                      final absoluteMax = constraints.maxWidth - 300.0;
                      if (newWidth > absoluteMax && absoluteMax >= widget.minMasterWidth) {
                         newWidth = absoluteMax;
                      }

                      _currentWidth = newWidth;
                    });
                  },
                  child: Container(
                    width: 7, // Wider hit area
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 1, // Visible part
                        color: _isDragging 
                            ? AppColors.tealMain 
                            : AppColors.textSecondary.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),

              // Detail View (Right Side)
              Expanded(
                child: widget.detailLayout,
              ),
            ],
          ),
        );
      },
    );
  }
}
