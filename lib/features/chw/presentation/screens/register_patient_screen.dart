import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/geohash.dart';
import '../../../../core/utils/validators.dart';
import '../../data/chw_repository.dart';
import '../../domain/chw_models.dart';
import '../providers/chw_provider.dart';

class RegisterPatientScreen extends ConsumerStatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  ConsumerState<RegisterPatientScreen> createState() =>
      _RegisterPatientScreenState();
}

class _RegisterPatientScreenState
    extends ConsumerState<RegisterPatientScreen> {
  final List<GlobalKey<FormState>> _stepFormKeys =
      List.generate(3, (_) => GlobalKey<FormState>());
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _sectorCtrl  = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String _sex       = 'MALE';
  String _hivStatus = 'POSITIVE';
  String _tbStatus  = 'ACTIVE';
  DateTime? _dob;
  bool _isLoading   = false;
  bool _hasSmartphone = false;
  int  _currentStep = 0;

  // ── RBC TB symptom screen ──
  bool _tbCough = false, _tbFever = false, _tbNightSweats = false,
      _tbWeightLoss = false, _tbChestPain = false;
  bool get _presumptiveTb =>
      _tbCough || _tbFever || _tbNightSweats || _tbWeightLoss || _tbChestPain;

  // ── Community HIV testing-eligibility risk screen ──
  bool _hivNeverTested = false, _hivPartnerPositive = false,
      _hivUnprotectedSex = false, _hivStiTreatment = false,
      _hivRecurrentIllness = false;
  bool get _hivTestingReferral =>
      _hivNeverTested || _hivPartnerPositive || _hivUnprotectedSex ||
      _hivStiTreatment || _hivRecurrentIllness;
  bool _referAnyway = false;
  final _referReasonCtrl = TextEditingController();

  String? _locationGeohash;
  bool _capturingLocation = false;

  /// Patient must explicitly consent, in person, before this record can be
  /// created (Rwanda Law No. 058/2021 — documented informed consent for
  /// digital storage of special-category health data).
  bool _consentGiven = false;
  static const String _kPatientConsentVersion = '2026-06-v1';

  // Populated after successful submission
  String? _referralId;
  String? _patientCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _sectorCtrl.dispose();
    _districtCtrl.dispose();
    _notesCtrl.dispose();
    _referReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _capturingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const FormatException('location_permission_denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final hash = encodeGeohash(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _locationGeohash = hash);
    } catch (e) {
      if (!mounted) return;
      final lang = ref.read(languageProvider);
      final msg = e is FormatException && e.message == 'location_permission_denied'
          ? AppL10n.t('location_permission_denied', lang)
          : ApiClient.friendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _capturingLocation = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final req = RegisterPatientRequest(
        fullName:      _nameCtrl.text.trim(),
        phoneNumber:   _phoneCtrl.text.trim(),
        village:       _villageCtrl.text.trim(),
        sector:        _sectorCtrl.text.trim().isEmpty ? null : _sectorCtrl.text.trim(),
        district:      _districtCtrl.text.trim(),
        dateOfBirth:   _dob,
        sex:           _sex,
        hivStatus:     _hivStatus,
        tbStatus:      _tbStatus,
        hasSmartphone: _hasSmartphone,
        screeningNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        locationGeohash: _locationGeohash,
        consentGiven: _consentGiven,
        consentVersion: _kPatientConsentVersion,
        tbSymptomCough: _tbCough,
        tbSymptomFever: _tbFever,
        tbSymptomNightSweats: _tbNightSweats,
        tbSymptomWeightLoss: _tbWeightLoss,
        tbSymptomChestPain: _tbChestPain,
        hivRiskNeverTested: _hivNeverTested,
        hivRiskPartnerPositive: _hivPartnerPositive,
        hivRiskUnprotectedSex: _hivUnprotectedSex,
        hivRiskStiTreatment: _hivStiTreatment,
        hivRiskRecurrentIllness: _hivRecurrentIllness,
        manualReferralReason:
            (!_hivTestingReferral && _referAnyway && _referReasonCtrl.text.trim().isNotEmpty)
                ? _referReasonCtrl.text.trim()
                : null,
      );

      final result = await ref.read(chwRepositoryProvider).screenPatient(req);

      setState(() {
        _referralId  = result['referralId'] as String?;
        _patientCode = result['patientCode'] as String?;
        _isLoading   = false;
      });

      ref.invalidate(chwPatientsProvider);
      ref.invalidate(chwDashboardProvider);

    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.friendlyError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final l = (String k) => AppL10n.t(k, lang);
    // ── Success screen ────────────────────────────────────────────────────────
    if (_referralId != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l('screening_complete')),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                l('provisional_record_created'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _nameCtrl.text.trim(),
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      l('referral_id_label'),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _referralId!,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_patientCode != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${l('patient_code_label')}: $_patientCode',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  l('referral_instructions_full'),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(l('back_to_patients')),
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Registration form ─────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l('screen_patient')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 3) {
              if (!_consentGiven) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l('patient_consent_required_notice')),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              _submit();
              return;
            }
            if (!_stepFormKeys[_currentStep].currentState!.validate()) return;
            if (_currentStep == 0 && _dob == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l('dob_required')),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            setState(() => _currentStep++);
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: (_isLoading || (_currentStep == 3 && !_consentGiven))
                      ? null
                      : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 44)),
                  child: _isLoading && _currentStep == 3
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_currentStep < 3 ? l('continue_btn') : l('submit_screening')),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 44)),
                    child: Text(l('back')),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            Step(
              title: Text(l('personal_info')),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _stepFormKeys[0],
                child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, l('full_name')),
                    decoration: InputDecoration(
                      labelText: '${l('full_name')} *',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: Validators.requiredPhone,
                    decoration: InputDecoration(
                      labelText: '${l('phone_number')} *',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      hintText: '+250 7XX XXX XXX',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: l('sex'),
                    value: _sex,
                    items: const ['MALE', 'FEMALE'],
                    labels: {'MALE': l('male'), 'FEMALE': l('female')},
                    onChanged: (v) => setState(() => _sex = v!),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l('date_of_birth'),
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _dob == null
                          ? l('not_set')
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                      style: TextStyle(
                        color: _dob == null ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AppColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l('has_smartphone'),
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(l('smartphone_desc'),
                        style: const TextStyle(fontSize: 11)),
                    value: _hasSmartphone,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _hasSmartphone = v),
                  ),
                ],
                ),
              ),
            ),
            Step(
              title: Text(l('location')),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _stepFormKeys[1],
                child: Column(
                children: [
                  TextFormField(
                    controller: _villageCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, l('village')),
                    decoration: InputDecoration(
                      labelText: '${l('village')} *',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sectorCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l('sector'),
                      prefixIcon: const Icon(Icons.map_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _districtCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, l('district')),
                    decoration: InputDecoration(
                      labelText: '${l('district')} *',
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _locationGeohash != null
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      color: _locationGeohash != null
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    title: Text(
                      _locationGeohash != null
                          ? l('location_captured')
                          : l('location_not_captured'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: _capturingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _captureLocation,
                            child: Text(l('capture_location')),
                          ),
                  ),
                ],
                ),
              ),
            ),
            Step(
              title: Text(l('suspected_condition')),
              isActive: _currentStep >= 2,
              content: Form(
                key: _stepFormKeys[2],
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l('field_observation_note'),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  _DropdownField(
                    label: l('hiv_status'),
                    value: _hivStatus,
                    items: const ['POSITIVE', 'NEGATIVE', 'UNKNOWN'],
                    labels: {
                      'POSITIVE': l('hiv_positive_suspected'),
                      'NEGATIVE': l('hiv_negative'),
                      'UNKNOWN':  l('hiv_unknown'),
                    },
                    onChanged: (v) => setState(() => _hivStatus = v!),
                  ),
                  const SizedBox(height: 18),

                  // ── HIV testing-eligibility risk screen ──────────────────
                  _ScreenHeader(title: l('hiv_risk_screen'), subtitle: l('hiv_risk_screen_sub')),
                  _ScreenQuestion(
                      text: l('hiv_q_never_tested'),
                      value: _hivNeverTested,
                      onChanged: (v) => setState(() => _hivNeverTested = v)),
                  _ScreenQuestion(
                      text: l('hiv_q_partner_positive'),
                      value: _hivPartnerPositive,
                      onChanged: (v) => setState(() => _hivPartnerPositive = v)),
                  _ScreenQuestion(
                      text: l('hiv_q_unprotected_sex'),
                      value: _hivUnprotectedSex,
                      onChanged: (v) => setState(() => _hivUnprotectedSex = v)),
                  _ScreenQuestion(
                      text: l('hiv_q_sti_treatment'),
                      value: _hivStiTreatment,
                      onChanged: (v) => setState(() => _hivStiTreatment = v)),
                  _ScreenQuestion(
                      text: l('hiv_q_recurrent_illness'),
                      value: _hivRecurrentIllness,
                      onChanged: (v) => setState(() => _hivRecurrentIllness = v)),
                  if (_hivTestingReferral)
                    _ScreenNotice(
                        icon: Icons.local_hospital_rounded,
                        text: l('hiv_testing_referral_notice'),
                        color: AppColors.info)
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(l('refer_anyway'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(l('refer_anyway_sub'),
                          style: const TextStyle(fontSize: 11)),
                      value: _referAnyway,
                      activeThumbColor: AppColors.info,
                      onChanged: (v) => setState(() {
                        _referAnyway = v;
                        if (!v) _referReasonCtrl.clear();
                      }),
                    ),
                    if (_referAnyway)
                      TextFormField(
                        controller: _referReasonCtrl,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            _referAnyway ? Validators.required(v, l('refer_reason')) : null,
                        decoration: InputDecoration(
                          labelText: '${l('refer_reason')} *',
                          hintText: l('refer_reason_hint'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 18),

                  _DropdownField(
                    label: l('tb_status'),
                    value: _tbStatus,
                    items: const ['ACTIVE', 'SUSPECTED', 'LATENT', 'NONE'],
                    labels: {
                      'ACTIVE':   l('tb_active_confirmed'),
                      'SUSPECTED':l('tb_suspected_genexpert'),
                      'LATENT':   l('tb_latent'),
                      'NONE':     l('tb_no_signs'),
                    },
                    onChanged: (v) => setState(() => _tbStatus = v!),
                  ),
                  const SizedBox(height: 18),

                  // ── RBC TB symptom screen ────────────────────────────────
                  _ScreenHeader(title: l('tb_symptom_screen'), subtitle: l('tb_symptom_screen_sub')),
                  _ScreenQuestion(
                      text: l('tb_q_cough'),
                      value: _tbCough,
                      onChanged: (v) => setState(() => _tbCough = v)),
                  _ScreenQuestion(
                      text: l('tb_q_fever'),
                      value: _tbFever,
                      onChanged: (v) => setState(() => _tbFever = v)),
                  _ScreenQuestion(
                      text: l('tb_q_night_sweats'),
                      value: _tbNightSweats,
                      onChanged: (v) => setState(() => _tbNightSweats = v)),
                  _ScreenQuestion(
                      text: l('tb_q_weight_loss'),
                      value: _tbWeightLoss,
                      onChanged: (v) => setState(() => _tbWeightLoss = v)),
                  _ScreenQuestion(
                      text: l('tb_q_chest_pain'),
                      value: _tbChestPain,
                      onChanged: (v) => setState(() => _tbChestPain = v)),
                  if (_presumptiveTb)
                    _ScreenNotice(
                        icon: Icons.coronavirus_rounded,
                        text: l('presumptive_tb_notice'),
                        color: AppColors.riskCritical),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l('screening_notes_optional'),
                      hintText: l('screening_notes_hint'),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
                ),
              ),
            ),
            Step(
              title: Text(l('patient_consent_title')),
              isActive: _currentStep >= 3,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l('patient_consent_body'),
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => setState(() => _consentGiven = !_consentGiven),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _consentGiven,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _consentGiven = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              l('patient_consent_checkbox'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_consentGiven)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        l('patient_consent_required_notice'),
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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

// ─── Structured screening helpers ─────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ScreenHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ScreenQuestion extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ScreenQuestion(
      {required this.text, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(text, style: const TextStyle(fontSize: 13)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

class _ScreenNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ScreenNotice(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String>? labels;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(labels?[e] ?? _capitalize(e))))
          .toList(),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
