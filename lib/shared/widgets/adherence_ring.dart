import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdherenceRing extends StatelessWidget {
  final double percentage; // 0–100
  final double size;
  final double strokeWidth;
  final bool showLabel;
  final String? subtitle;

  const AdherenceRing({
    super.key,
    required this.percentage,
    this.size = 120,
    this.strokeWidth = 10,
    this.showLabel = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(percentage);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: color,
                trackColor: color.withValues(alpha: 0.12),
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          if (showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => Text(
                    '${val.toInt()}%',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: size * 0.1,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _color(double pct) {
    if (pct >= 80) return AppColors.riskLow;
    if (pct >= 60) return AppColors.riskModerate;
    if (pct >= 40) return AppColors.riskHigh;
    return AppColors.riskCritical;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // start at top (-90°)
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
