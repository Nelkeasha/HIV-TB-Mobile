import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../providers/chw_provider.dart';
import '../../data/chw_repository.dart';
import '../../domain/chw_models.dart';

class HomeVisitScreen extends ConsumerStatefulWidget {
  final String patientId;
  const HomeVisitScreen({super.key, required this.patientId});

  @override
  ConsumerState<HomeVisitScreen> createState() => _HomeVisitScreenState();
}

class _HomeVisitScreenState extends ConsumerState<HomeVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _symptomsCtrl = TextEditingController();
  final _sideEffectsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pillRecordedCtrl = TextEditingController();
  final _pillExpectedCtrl = TextEditingController();

  // State
  String _adherenceStatus = 'GOOD';
  int? _adverseEventGrade;
  bool _referralInitiated = false;
  bool _pillCountEnabled = false;
  DateTime? _nextVisitDate;
  bool _isLoading = false;

  // Diagnosis drives which cards show (set when the patient loads).
  String? _diagnosisType; // HIV | TB | HIV_TB_COINFECTION
  bool get _isHiv =>
      _diagnosisType == 'HIV' || _diagnosisType == 'HIV_TB_COINFECTION';
  bool get _isTb =>
      _diagnosisType == 'TB' || _diagnosisType == 'HIV_TB_COINFECTION';

  // Card A — ART side effects: jaundice | neuropathy | vomiting | rash
  final Set<String> _artSE = {};
  // Card B — DOT + TB side effects: jaundice | vomiting | jointPain | visionChanges | rash
  bool _dotObserved = false;
  final Set<String> _tbSE = {};
  bool _ventilationOk = false;
  bool _coughHygieneOk = false;
  DateTime? _nextDotDate;

  void _toggle(Set<String> set, String code, bool on) =>
      setState(() => on ? set.add(code) : set.remove(code));

  static const _adherenceOptions = [
    ('GOOD', 'adherence_good', Icons.check_circle_rounded, AppColors.riskLow),
    ('PARTIAL', 'adherence_partial', Icons.warning_rounded, AppColors.riskModerate),
    ('POOR', 'adherence_poor', Icons.cancel_rounded, AppColors.riskHigh),
    ('MISSED', 'adherence_missed', Icons.block_rounded, AppColors.riskCritical),
  ];

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _sideEffectsCtrl.dispose();
    _notesCtrl.dispose();
    _pillRecordedCtrl.dispose();
    _pillExpectedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNextVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextVisitDate = picked);
  }

  Future<void> _pickNextDotDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextDotDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final anySideEffect = _artSE.isNotEmpty || _tbSE.isNotEmpty;
    final hasObservation = anySideEffect ||
        _dotObserved ||
        _notesCtrl.text.trim().isNotEmpty ||
        (_isHiv && _pillCountEnabled && _pillRecordedCtrl.text.trim().isNotEmpty) ||
        _adverseEventGrade != null ||
        _nextDotDate != null;
    if (!hasObservation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Record at least one observation — DOT, a side effect, a pill count, or a note.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final req = HomeVisitRequest(
        patientId: widget.patientId,
        visitDate: AppDateUtils.nowForServer(),
        adherenceStatus: _adherenceStatus,
        // Card A (HIV / ART)
        pillCountRecorded: (_isHiv && _pillCountEnabled)
            ? int.tryParse(_pillRecordedCtrl.text)
            : null,
        pillCountExpected: (_isHiv && _pillCountEnabled)
            ? int.tryParse(_pillExpectedCtrl.text)
            : null,
        artSideEffects: _isHiv
            ? {
                'jaundice': _artSE.contains('jaundice'),
                'neuropathy': _artSE.contains('neuropathy'),
                'vomiting': _artSE.contains('vomiting'),
                'rash': _artSE.contains('rash'),
              }
            : null,
        // Card B (TB / DOT)
        dotObserved: _isTb ? _dotObserved : null,
        tbSideEffects: _isTb
            ? {
                'jaundice': _tbSE.contains('jaundice'),
                'vomiting': _tbSE.contains('vomiting'),
                'jointPain': _tbSE.contains('jointPain'),
                'visionChanges': _tbSE.contains('visionChanges'),
                'rash': _tbSE.contains('rash'),
              }
            : null,
        homeVentilationOk: _isTb ? _ventilationOk : null,
        coughHygieneOk: _isTb ? _coughHygieneOk : null,
        nextDotDate: _isTb ? _nextDotDate : null,
        psychosocialNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        nextVisitDate: _nextVisitDate,
        // Adverse-event grade applies to either card (severe ART or TB reactions).
        adverseEventGrade: _adverseEventGrade,
        referralInitiated: (_adverseEventGrade != null && _adverseEventGrade! >= 3)
            ? _referralInitiated
            : null,
      );
      final queued = await ref.read(chwRepositoryProvider).recordVisit(req);
      ref.invalidate(visitHistoryProvider(widget.patientId));
      ref.invalidate(patientDetailProvider(widget.patientId));
      if (mounted) {
        final lang = ref.read(languageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(queued ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppL10n.t(queued ? 'visit_queued' : 'visit_saved', lang)),
              ),
            ]),
            backgroundColor: queued ? AppColors.warning : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.friendlyError(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    final patientAsync = ref.watch(patientDetailProvider(widget.patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('home_visit')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: patientAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _buildForm(patientName: null, lang: lang, l: l),
        data: (p) {
          _diagnosisType = p.diagnosisType;
          return _buildForm(patientName: p.fullName, lang: lang, l: l);
        },
      ),
    );
  }

  Widget _buildForm({required String? patientName, required String lang, required String Function(String) l}) {
    return Form(
      key: _formKey,
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient + date header ─────────────────────────────────────
              _VisitHeader(
                  patientName: patientName, visitDate: DateTime.now(), lang: lang),
              const SizedBox(height: 24),

              // ── Adherence status ──────────────────────────────────────────
              _SectionTitle(
                  title: l('adherence_status'),
                  subtitle: l('adherence_desc'),
                  required: true),
              const SizedBox(height: 12),
              _AdherenceSelector(
                selected: _adherenceStatus,
                options: _adherenceOptions,
                lang: lang,
                onSelect: (v) => setState(() => _adherenceStatus = v),
              ),
              const SizedBox(height: 24),

              // ══ Card A — HIV / ART monitoring ═════════════════════════════
              if (_isHiv) ...[
                _CardHeader(
                    icon: Icons.bloodtype_rounded,
                    title: l('card_art_title'),
                    color: AppColors.info),
                const SizedBox(height: 12),
                _SectionTitle(
                    title: l('pill_count'), subtitle: l('pill_count_desc')),
                const SizedBox(height: 10),
                _ToggleCard(
                  title: l('enable_pill_count'),
                  subtitle: l('record_pill_count_subtitle'),
                  value: _pillCountEnabled,
                  onChanged: (v) => setState(() {
                    _pillCountEnabled = v;
                    if (!v) {
                      _pillRecordedCtrl.clear();
                      _pillExpectedCtrl.clear();
                    }
                  }),
                  activeColor: AppColors.primary,
                ),
                if (_pillCountEnabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pillRecordedCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (_isHiv && _pillCountEnabled)
                              ? Validators.positiveInt(v, l('pills_found'))
                              : null,
                          decoration: InputDecoration(
                            labelText: l('pills_found'),
                            suffixText: l('unit_pills'),
                            prefixIcon: const Icon(Icons.medication_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _pillExpectedCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (_isHiv && _pillCountEnabled)
                              ? Validators.positiveInt(v, l('pills_expected'))
                              : null,
                          decoration: InputDecoration(
                            labelText: l('pills_expected'),
                            suffixText: l('unit_pills'),
                            prefixIcon: const Icon(
                                Icons.format_list_numbered_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pillRecordedCtrl.text.isNotEmpty &&
                      _pillExpectedCtrl.text.isNotEmpty)
                    _PillDiscrepancyHint(
                      recorded: int.tryParse(_pillRecordedCtrl.text),
                      expected: int.tryParse(_pillExpectedCtrl.text),
                      lang: lang,
                    ),
                ],
                const SizedBox(height: 16),
                _SectionTitle(
                    title: l('art_side_effects'), subtitle: l('art_side_effects_sub')),
                const SizedBox(height: 8),
                _ChecklistTile(label: l('se_jaundice'), value: _artSE.contains('jaundice'), accent: AppColors.riskCritical, onChanged: (v) => _toggle(_artSE, 'jaundice', v)),
                _ChecklistTile(label: l('se_neuropathy'), value: _artSE.contains('neuropathy'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_artSE, 'neuropathy', v)),
                _ChecklistTile(label: l('se_vomiting'), value: _artSE.contains('vomiting'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_artSE, 'vomiting', v)),
                _ChecklistTile(label: l('se_rash'), value: _artSE.contains('rash'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_artSE, 'rash', v)),
                const SizedBox(height: 24),
              ],

              // ══ Card B — TB / Directly Observed Therapy ═══════════════════
              if (_isTb) ...[
                _CardHeader(
                    icon: Icons.coronavirus_rounded,
                    title: l('card_dot_title'),
                    color: AppColors.riskCritical),
                const SizedBox(height: 6),
                Text(l('dot_regulatory_note'),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint, height: 1.4)),
                const SizedBox(height: 12),
                _ToggleCard(
                  title: l('dot_observed'),
                  subtitle: l('dot_observed_sub'),
                  value: _dotObserved,
                  onChanged: (v) => setState(() => _dotObserved = v),
                  activeColor: AppColors.riskLow,
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                    title: l('tb_side_effects'), subtitle: l('tb_side_effects_sub')),
                const SizedBox(height: 8),
                _ChecklistTile(label: l('se_jaundice'), value: _tbSE.contains('jaundice'), accent: AppColors.riskCritical, onChanged: (v) => _toggle(_tbSE, 'jaundice', v)),
                _ChecklistTile(label: l('se_vomiting'), value: _tbSE.contains('vomiting'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_tbSE, 'vomiting', v)),
                _ChecklistTile(label: l('se_joint_pain'), value: _tbSE.contains('jointPain'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_tbSE, 'jointPain', v)),
                _ChecklistTile(label: l('se_vision_changes'), value: _tbSE.contains('visionChanges'), accent: AppColors.riskCritical, onChanged: (v) => _toggle(_tbSE, 'visionChanges', v)),
                _ChecklistTile(label: l('se_rash'), value: _tbSE.contains('rash'), accent: AppColors.riskModerate, onChanged: (v) => _toggle(_tbSE, 'rash', v)),
                const SizedBox(height: 16),
                _SectionTitle(
                    title: l('infection_control'), subtitle: l('infection_control_sub')),
                const SizedBox(height: 8),
                _ToggleCard(
                  title: l('home_ventilation_ok'),
                  subtitle: l('home_ventilation_sub'),
                  value: _ventilationOk,
                  onChanged: (v) => setState(() => _ventilationOk = v),
                  activeColor: AppColors.riskLow,
                ),
                const SizedBox(height: 8),
                _ToggleCard(
                  title: l('cough_hygiene_ok'),
                  subtitle: l('cough_hygiene_sub'),
                  value: _coughHygieneOk,
                  onChanged: (v) => setState(() => _coughHygieneOk = v),
                  activeColor: AppColors.riskLow,
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: l('next_dot'), subtitle: l('next_dot_sub')),
                const SizedBox(height: 10),
                _NextVisitPicker(
                  selected: _nextDotDate,
                  onTap: _pickNextDotDate,
                  onClear: () => setState(() => _nextDotDate = null),
                  lang: lang,
                ),
                const SizedBox(height: 24),
              ],

              // ══ Adverse-event severity (shown when any side effect flagged) ═
              if (_artSE.isNotEmpty || _tbSE.isNotEmpty) ...[
                _SectionTitle(
                    title: l('adverse_event_grade'),
                    subtitle: l('adverse_event_grade_hint')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4].map((grade) {
                    final selected = _adverseEventGrade == grade;
                    final color = grade >= 3 ? AppColors.riskCritical : AppColors.riskModerate;
                    return ChoiceChip(
                      label: Text('${l('grade_label')} $grade'),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        _adverseEventGrade = v ? grade : null;
                        if (_adverseEventGrade == null || _adverseEventGrade! < 3) {
                          _referralInitiated = false;
                        }
                      }),
                      selectedColor: color.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: selected ? color : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: selected ? color : AppColors.divider),
                    );
                  }).toList(),
                ),
                if (_adverseEventGrade != null && _adverseEventGrade! >= 3) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 16, color: AppColors.riskCritical),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(l('grade_severe_alert_notice'),
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.riskCritical,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToggleCard(
                    title: l('referral_initiated'),
                    subtitle: l('referral_initiated_sub'),
                    value: _referralInitiated,
                    onChanged: (v) => setState(() => _referralInitiated = v),
                    activeColor: AppColors.riskCritical,
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // ── Psychosocial notes ────────────────────────────────────────
              _SectionTitle(
                  title: l('wellbeing'),
                  subtitle: l('wellbeing_subtitle')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l('notes_optional'),
                  hintText: l('notes_hint'),
                  prefixIcon: const Icon(Icons.psychology_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 24),

              // ── Next visit date ───────────────────────────────────────────
              _SectionTitle(
                  title: l('next_visit'),
                  subtitle: l('schedule_next')),
              const SizedBox(height: 10),
              _NextVisitPicker(
                selected: _nextVisitDate,
                onTap: _pickNextVisitDate,
                onClear: () => setState(() => _nextVisitDate = null),
                lang: lang,
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isLoading ? l('saving') : l('save_visit'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Visit Header ─────────────────────────────────────────────────────────────

class _VisitHeader extends StatelessWidget {
  final String? patientName;
  final DateTime visitDate;
  final String lang;
  const _VisitHeader({required this.patientName, required this.visitDate, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName ?? AppL10n.t('home_visit', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateUtils.formatDateTime(visitDate),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool required;
  const _SectionTitle(
      {required this.title, this.subtitle, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error),
              ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

// ─── Adherence Selector ───────────────────────────────────────────────────────

class _AdherenceSelector extends StatelessWidget {
  final String selected;
  final List<(String, String, IconData, Color)> options;
  final String lang;
  final ValueChanged<String> onSelect;
  const _AdherenceSelector(
      {required this.selected,
      required this.options,
      required this.lang,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (value, label, icon, color) = opt;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 22, color: isSelected ? color : AppColors.textHint),
                  const SizedBox(height: 6),
                  Text(
                    AppL10n.t(label, lang),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Toggle Card ──────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: value ? activeColor.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
              value: value, onChanged: onChanged, activeThumbColor: activeColor),
        ],
      ),
    );
  }
}

// ─── Pill Discrepancy Hint ────────────────────────────────────────────────────

class _PillDiscrepancyHint extends StatelessWidget {
  final int? recorded;
  final int? expected;
  final String lang;
  const _PillDiscrepancyHint({required this.recorded, required this.expected, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (recorded == null || expected == null) return const SizedBox.shrink();
    final diff = expected! - recorded!;
    final hasDiscrepancy = diff > 0;
    final color = hasDiscrepancy ? AppColors.riskCritical : AppColors.success;
    final icon = hasDiscrepancy
        ? Icons.warning_amber_rounded
        : Icons.check_circle_rounded;
    final msg = hasDiscrepancy
        ? '$diff ${AppL10n.t('pill_discrepancy_msg', lang)}'
        : AppL10n.t('pill_count_match', lang);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(msg, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

// ─── Checklist Tile (structured symptom / side-effect) ────────────────────────

class _ChecklistTile extends StatelessWidget {
  final String label;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _ChecklistTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? accent.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? accent.withValues(alpha: 0.5) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: value ? accent : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Presumptive TB Banner ────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _CardHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next Visit Picker ────────────────────────────────────────────────────────

class _NextVisitPicker extends StatelessWidget {
  final DateTime? selected;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String lang;
  const _NextVisitPicker(
      {required this.selected,
      required this.onTap,
      required this.onClear,
      required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.primaryContainer
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 20,
              color:
                  selected != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected != null
                    ? AppDateUtils.formatDate(selected!)
                    : AppL10n.t('set_next_visit', lang),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selected != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
