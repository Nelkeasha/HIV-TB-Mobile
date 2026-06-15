import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RiskBadge extends StatelessWidget {
  final String level;
  final bool large;

  const RiskBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _color(level);
    final bg = _bg(level);
    final icon = _icon(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: large ? 14 : 12, color: color),
          ],
        ],
      ),
    );
  }

  Color _color(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.riskLow;
    }
  }

  Color _bg(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.riskCriticalBg;
      case 'HIGH':
        return AppColors.riskHighBg;
      case 'MODERATE':
        return AppColors.riskModerateBg;
      default:
        return AppColors.riskLowBg;
    }
  }

  IconData? _icon(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return Icons.warning_rounded;
      case 'HIGH':
        return Icons.arrow_upward_rounded;
      default:
        return null;
    }
  }
}
