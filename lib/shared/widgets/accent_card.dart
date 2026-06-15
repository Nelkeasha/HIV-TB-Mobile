import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A rounded card with a colored accent bar along the left edge.
///
/// Reproduces the original `Border(left: BorderSide(color: accentColor,
/// width: accentWidth))` + `borderRadius` design (which is invalid for
/// non-uniform borders and crashes in debug mode) using a `Stack` with a
/// `Positioned` accent bar instead, while preserving the exact content
/// insets the original border-based layout produced.
class AccentCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;
  final double radius;
  final double accentWidth;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? backgroundColor;

  /// Whether the original design also drew a 1px [AppColors.divider] border
  /// on the top/right/bottom edges (in addition to the left accent).
  final bool showDividerBorder;

  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.radius = 14,
    this.accentWidth = 4,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.showDividerBorder = false,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final accentRadius = BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );

    final contentPadding = EdgeInsets.fromLTRB(
      padding.left + accentWidth,
      padding.top + (showDividerBorder ? 1 : 0),
      padding.right + (showDividerBorder ? 1 : 0),
      padding.bottom + (showDividerBorder ? 1 : 0),
    );

    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: showDividerBorder ? Border.all(color: AppColors.divider) : null,
        boxShadow: boxShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: accentWidth,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: accentRadius,
              ),
            ),
          ),
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: card,
        ),
      );
    }

    return Container(margin: margin, child: card);
  }
}
