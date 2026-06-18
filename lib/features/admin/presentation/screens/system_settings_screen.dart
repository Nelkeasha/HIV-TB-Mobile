import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  // Alert thresholds
  int _missedDoseThreshold = 2;
  int _lowStockDays = 14;
  int _confirmWindowMinutes = 45;
  int _highRiskThreshold = 70;
  int _criticalRiskThreshold = 85;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(adminRepositoryProvider).getSettings();
      setState(() {
        _missedDoseThreshold = settings.missedDoseThreshold;
        _lowStockDays = settings.lowStockDays;
        _confirmWindowMinutes = settings.confirmWindowMinutes;
        _highRiskThreshold = settings.highRiskThreshold;
        _criticalRiskThreshold = settings.criticalRiskThreshold;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load settings: ${ApiClient.friendlyError(e)}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('System Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveSettings,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert thresholds
            _SectionCard(
              title: 'Alert Thresholds',
              icon: Icons.tune_rounded,
              color: AppColors.warning,
              children: [
                _SliderSetting(
                  label: 'Missed Dose Alert (doses)',
                  value: _missedDoseThreshold.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  display: '$_missedDoseThreshold dose${_missedDoseThreshold > 1 ? 's' : ''}',
                  onChanged: (v) => setState(() => _missedDoseThreshold = v.round()),
                ),
                const Divider(height: 1),
                _SliderSetting(
                  label: 'Low Stock Warning (days)',
                  value: _lowStockDays.toDouble(),
                  min: 7,
                  max: 30,
                  divisions: 23,
                  display: '$_lowStockDays days',
                  onChanged: (v) => setState(() => _lowStockDays = v.round()),
                ),
                const Divider(height: 1),
                _SliderSetting(
                  label: 'Confirmation Window (minutes)',
                  value: _confirmWindowMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  display: '$_confirmWindowMinutes min',
                  onChanged: (v) => setState(() => _confirmWindowMinutes = v.round()),
                ),
                const Divider(height: 1),
                _SliderSetting(
                  label: 'High Risk Score Threshold',
                  value: _highRiskThreshold.toDouble(),
                  min: 50,
                  max: 90,
                  divisions: 8,
                  display: '$_highRiskThreshold / 100',
                  onChanged: (v) => setState(() => _highRiskThreshold = v.round()),
                ),
                const Divider(height: 1),
                _SliderSetting(
                  label: 'Critical Risk Score Threshold',
                  value: _criticalRiskThreshold.toDouble(),
                  min: 70,
                  max: 99,
                  divisions: 10,
                  display: '$_criticalRiskThreshold / 100',
                  onChanged: (v) => setState(() => _criticalRiskThreshold = v.round()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Medication list
            _SectionCard(
              title: 'Medication List',
              icon: Icons.medication_outlined,
              color: AppColors.primary,
              children: [
                _InfoTile(icon: Icons.add_circle_outline, label: 'Add Medication', onTap: () => _comingSoon(context)),
                const Divider(height: 1),
                _InfoTile(icon: Icons.edit_outlined, label: 'Edit Medications', onTap: () => _comingSoon(context)),
              ],
            ),
            const SizedBox(height: 16),

            // FHIR configuration
            _SectionCard(
              title: 'FHIR Integration',
              icon: Icons.sync_alt_rounded,
              color: AppColors.info,
              children: [
                _InfoRow(label: 'EHR Base URL', value: 'Not configured'),
                const Divider(height: 1),
                _InfoRow(label: 'Last Sync', value: 'Never'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.settings_outlined, label: 'Configure FHIR Endpoint', onTap: () => _comingSoon(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Notification settings
            _SectionCard(
              title: 'Notification Settings',
              icon: Icons.notifications_outlined,
              color: AppColors.accent,
              children: [
                _InfoRow(label: 'Firebase', value: 'Connected'),
                const Divider(height: 1),
                _InfoRow(label: "Africa's Talking SMS", value: 'Not configured'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.settings_outlined, label: 'Configure SMS Gateway', onTap: () => _comingSoon(context)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateSettings(SystemSettingsModel(
            missedDoseThreshold: _missedDoseThreshold,
            lowStockDays: _lowStockDays,
            confirmWindowMinutes: _confirmWindowMinutes,
            highRiskThreshold: _highRiskThreshold,
            criticalRiskThreshold: _criticalRiskThreshold,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${ApiClient.friendlyError(e)}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be available in the next update'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color, letterSpacing: 0.3)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;
  const _SliderSetting({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.display, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    trailing: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 20),
    title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
