import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';

// ── Colour tokens ──────────────────────────────────────────────────────────────
const _indigo = Color(0xFF283593);
const _coral = Color(0xFFE57373);
const _surface = Color(0xFFF5F5F5);

class AdminReportScreen extends ConsumerWidget {
  const AdminReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportProvider);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('System Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminReportProvider),
          ),
        ],
      ),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _indigo)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: _coral),
                const SizedBox(height: 12),
                Text('Failed to load report',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminReportProvider),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _indigo, foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (r) => _ReportBody(report: r),
      ),
    );
  }
}

// ── Report body ────────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  final AdminReportModel report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GeneratedBanner(generatedAt: report.generatedAt),
        const SizedBox(height: 16),
        _UsersCard(report: report),
        const SizedBox(height: 12),
        _FacilitiesCard(report: report),
        const SizedBox(height: 12),
        _PatientOverviewCard(report: report),
        const SizedBox(height: 12),
        _RiskDistributionCard(report: report),
        const SizedBox(height: 12),
        _AdherenceCard(report: report),
        const SizedBox(height: 12),
        _AlertCard(report: report),
        const SizedBox(height: 12),
        _FhirSyncCard(report: report),
        const SizedBox(height: 12),
        _LtfuCard(report: report),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Generated banner ───────────────────────────────────────────────────────────

class _GeneratedBanner extends StatelessWidget {
  final DateTime generatedAt;
  const _GeneratedBanner({required this.generatedAt});

  @override
  Widget build(BuildContext context) {
    final d = generatedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final label =
        '${d.day} ${months[d.month]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('Generated $label',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        const Text('System-wide',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic)),
      ],
    );
  }
}

// ── Section card shell ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── System users ───────────────────────────────────────────────────────────────

class _UsersCard extends StatelessWidget {
  final AdminReportModel report;
  const _UsersCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'System Users',
      icon: Icons.manage_accounts_rounded,
      iconColor: _indigo,
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _BigStat(
                    label: 'Total Users',
                    value: '${report.totalUsers}',
                    color: _indigo)),
            Expanded(
                child: _BigStat(
                    label: 'Active',
                    value: '${report.activeUsers}',
                    color: Colors.green.shade600)),
            Expanded(
                child: _BigStat(
                    label: 'Inactive',
                    value: '${report.inactiveUsers}',
                    color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _RoleTable(report: report),
        ],
      ),
    );
  }
}

class _RoleTable extends StatelessWidget {
  final AdminReportModel report;
  const _RoleTable({required this.report});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('CHWs', report.totalChw, Icons.directions_walk_rounded, AppColors.primary),
      ('Providers', report.totalProviders, Icons.local_hospital_rounded,
          Colors.blue.shade700),
      ('Supervisors', report.totalSupervisors, Icons.supervisor_account_rounded,
          Colors.green.shade700),
      ('Patients', report.totalPatients, Icons.person_rounded,
          Colors.purple.shade600),
    ];
    return Column(
      children: rows.map((r) {
        final (label, count, icon, color) = r;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13))),
              Text('$count',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Facilities ─────────────────────────────────────────────────────────────────

class _FacilitiesCard extends StatelessWidget {
  final AdminReportModel report;
  const _FacilitiesCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Facilities',
      icon: Icons.business_rounded,
      iconColor: _indigo,
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _SmallStat(
                    label: 'Total',
                    value: '${report.totalFacilities}',
                    color: _indigo)),
            Expanded(
                child: _SmallStat(
                    label: 'Active',
                    value: '${report.activeFacilities}',
                    color: Colors.green.shade600)),
          ]),
          if (report.facilityBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const _FacilityTableHeader(),
            const Divider(height: 1),
            ...report.facilityBreakdown.map((f) => _FacilityRow(row: f)),
          ],
        ],
      ),
    );
  }
}

class _FacilityTableHeader extends StatelessWidget {
  const _FacilityTableHeader();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Facility')),
          Expanded(flex: 1, child: _HeaderCell('Pts', center: true)),
          Expanded(flex: 1, child: _HeaderCell('CHWs', center: true)),
          Expanded(flex: 1, child: _HeaderCell('Adh%', center: true)),
          Expanded(flex: 1, child: _HeaderCell('Risk', center: true)),
        ],
      ),
    );
  }
}

class _FacilityRow extends StatelessWidget {
  final FacilityReportRowModel row;
  const _FacilityRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final hasRisk = row.highRiskPatients > 0;
    final pct = row.adherenceAvg;
    final pctColor = pct == null
        ? Colors.grey
        : pct >= 80
            ? Colors.green.shade700
            : pct >= 60
                ? Colors.orange
                : _coral;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.facilityName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(row.district,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Text('${row.activePatients}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 1,
              child: Text('${row.totalChws}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 1,
            child: Text(
              pct != null ? '${pct.toStringAsFixed(0)}%' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: pctColor),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${row.highRiskPatients}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasRisk ? FontWeight.bold : null,
                    color: hasRisk ? _coral : null)),
          ),
        ],
      ),
    );
  }
}

// ── Patient overview ───────────────────────────────────────────────────────────

class _PatientOverviewCard extends StatelessWidget {
  final AdminReportModel report;
  const _PatientOverviewCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Patient Overview',
      icon: Icons.people_rounded,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          _BigStat(
              label: 'Total Active Patients',
              value: '${report.totalActivePatients}',
              color: AppColors.primary),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _SmallStat(
                    label: 'HIV Only',
                    value: '${report.hivOnly}',
                    color: Colors.blue.shade700)),
            Expanded(
                child: _SmallStat(
                    label: 'TB Only',
                    value: '${report.tbOnly}',
                    color: Colors.orange.shade700)),
            Expanded(
                child: _SmallStat(
                    label: 'HIV+TB',
                    value: '${report.hivTbCoinfection}',
                    color: Colors.purple.shade600)),
          ]),
        ],
      ),
    );
  }
}

// ── Risk distribution ──────────────────────────────────────────────────────────

class _RiskDistributionCard extends StatelessWidget {
  final AdminReportModel report;
  const _RiskDistributionCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.totalActivePatients;
    return _SectionCard(
      title: 'Risk Distribution',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      child: Column(
        children: [
          _RiskBar(label: 'Critical', count: report.riskCritical, total: total,
              color: const Color(0xFFB71C1C)),
          _RiskBar(label: 'High', count: report.riskHigh, total: total, color: _coral),
          _RiskBar(label: 'Moderate', count: report.riskModerate, total: total,
              color: Colors.orange),
          _RiskBar(label: 'Low', count: report.riskLow, total: total,
              color: Colors.green.shade600),
          if (report.riskUnscored > 0)
            _RiskBar(label: 'Unscored', count: report.riskUnscored, total: total,
                color: Colors.grey),
        ],
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _RiskBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 72,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 32,
              child: Text('$count',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color))),
        ],
      ),
    );
  }
}

// ── Adherence ──────────────────────────────────────────────────────────────────

class _AdherenceCard extends ConsumerWidget {
  final AdminReportModel report;
  const _AdherenceCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = report.systemAdherenceAvg.clamp(0, 100);
    final color = pct >= 80
        ? Colors.green.shade600
        : pct >= 60
            ? Colors.orange
            : _coral;
    return _SectionCard(
      title: 'Adherence (System-wide)',
      icon: Icons.medication_rounded,
      iconColor: color,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('system average',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).toDouble(),
              minHeight: 12,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _SmallStat(
                    label: 'Below Threshold',
                    value: '${report.belowThresholdCount}',
                    color: _coral)),
            Expanded(
                child: _SmallStat(
                    label: 'False Confirmation Flags',
                    value: '${report.falseConfirmationFlagCount}',
                    color: Colors.amber.shade700)),
          ]),
          if (report.belowThresholdCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Patients below threshold',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ),
            const SizedBox(height: 8),
            _BelowThresholdList(ref: ref),
          ],
        ],
      ),
    );
  }
}

class _BelowThresholdList extends StatelessWidget {
  final WidgetRef ref;
  const _BelowThresholdList({required this.ref});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(belowThresholdPatientsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
            height: 16, width: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Text('Could not load patient list',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      data: (patients) {
        if (patients.isEmpty) {
          return Text('No patients currently below threshold',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500));
        }
        final shown = patients.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${p.fullName}  ·  ${p.patientCode}',
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (p.chwName != null)
                      Text(p.chwName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            if (patients.length > shown.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+${patients.length - shown.length} more',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              ),
          ],
        );
      },
    );
  }
}

// ── Alerts ─────────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AdminReportModel report;
  const _AlertCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Active Alerts',
      icon: Icons.notifications_active_rounded,
      iconColor: _coral,
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _SmallStat(
                    label: 'Total Unresolved',
                    value: '${report.unresolvedAlerts}',
                    color: Colors.blueGrey)),
            Expanded(
                child: _SmallStat(
                    label: 'Critical',
                    value: '${report.criticalAlerts}',
                    color: const Color(0xFFB71C1C))),
            Expanded(
                child: _SmallStat(
                    label: 'Warning',
                    value: '${report.warningAlerts}',
                    color: Colors.orange)),
          ]),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _SmallStat(
                label: 'Missed Dose Alerts',
                value: '${report.missedDoseAlerts}',
                color: Colors.deepOrange),
          ),
        ],
      ),
    );
  }
}

// ── FHIR sync ──────────────────────────────────────────────────────────────────

class _FhirSyncCard extends StatelessWidget {
  final AdminReportModel report;
  const _FhirSyncCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.fhirSyncPending +
        report.fhirSyncSynced +
        report.fhirSyncFailed;
    return _SectionCard(
      title: 'FHIR Sync Status',
      icon: Icons.sync_rounded,
      iconColor: _indigo,
      child: Column(
        children: [
          _FhirBar(
              label: 'Synced',
              count: report.fhirSyncSynced,
              total: total,
              color: Colors.green.shade600),
          _FhirBar(
              label: 'Pending',
              count: report.fhirSyncPending,
              total: total,
              color: Colors.amber.shade700),
          _FhirBar(
              label: 'Failed',
              count: report.fhirSyncFailed,
              total: total,
              color: _coral),
        ],
      ),
    );
  }
}

class _FhirBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _FhirBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 64,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 32,
              child: Text('$count',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color))),
        ],
      ),
    );
  }
}

// ── LTFU tracing ───────────────────────────────────────────────────────────────

class _LtfuCard extends StatelessWidget {
  final AdminReportModel report;
  const _LtfuCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'LTFU Tracing',
      icon: Icons.person_search_rounded,
      iconColor: _coral,
      child: Row(children: [
        Expanded(
            child: _SmallStat(
                label: 'Active Cases',
                value: '${report.activeLtfuTasks}',
                color: report.activeLtfuTasks > 0
                    ? _coral
                    : Colors.green.shade600)),
        Expanded(
            child: _SmallStat(
                label: 'Confirmed',
                value: '${report.ltfuConfirmedCount}',
                color: report.ltfuConfirmedCount > 0
                    ? const Color(0xFFB71C1C)
                    : Colors.green.shade600)),
        Expanded(
            child: _SmallStat(
                label: 'Escalated',
                value: '${report.escalatedCount}',
                color: report.escalatedCount > 0
                    ? Colors.amber.shade700
                    : Colors.green.shade600)),
      ]),
    );
  }
}

// ── Shared stat widgets ────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BigStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],
      );
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SmallStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
      );
}
