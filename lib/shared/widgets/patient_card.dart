import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../models/patient_model.dart';
import 'risk_badge.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;
  final bool showRisk;

  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
    this.subtitle,
    this.trailing,
    this.showRisk = true,
  });

  @override
  Widget build(BuildContext context) {
    final risk = patient.latestRiskScore;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: risk != null
                  ? _borderColor(risk.riskLevel).withValues(alpha: 0.3)
                  : AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(name: patient.fullName, riskLevel: risk?.riskLevel),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ??
                          [
                            patient.patientCode,
                            if (patient.village != null) patient.village!,
                          ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (risk != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (showRisk) RiskBadge(level: risk.riskLevel),
                          if (risk.adherence30d != null) ...[
                            const SizedBox(width: 8),
                            _AdherenceChip(
                              pct: (risk.adherence30d! * 100).toInt(),
                            ),
                          ],
                          if (risk.calculatedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              AppDateUtils.timeAgo(risk.calculatedAt!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _borderColor(String level) {
    switch (level) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.divider;
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? riskLevel;

  const _Avatar({required this.name, this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final color = _avatarColor(riskLevel);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _avatarColor(String? level) {
    switch (level) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MODERATE':
        return AppColors.riskModerate;
      default:
        return AppColors.primary;
    }
  }
}

class _AdherenceChip extends StatelessWidget {
  final int pct;
  const _AdherenceChip({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 80
        ? AppColors.riskLow
        : pct >= 60
            ? AppColors.riskModerate
            : AppColors.riskCritical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pct% adherence',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
