import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_overlay.dart' show AppLoader, ErrorView;
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class CreateStaffScreen extends ConsumerStatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  ConsumerState<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends ConsumerState<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'CHW';
  FacilityModel? _selectedFacility;
  bool _isSubmitting = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  static const _roles = [
    ('Community Health Worker', 'CHW', Icons.directions_walk_rounded),
    ('Facility Provider', 'FACILITY_PROVIDER', Icons.medical_services_rounded),
    ('Supervisor', 'SUPERVISOR', Icons.supervisor_account_rounded),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _villageCtrl.dispose();
    _sectorCtrl.dispose();
    _districtCtrl.dispose();
    _specCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<FacilityModel> facilities) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a facility'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final body = _buildBody();
    final result = await ref
        .read(adminUsersProvider.notifier)
        .createStaff(_selectedRole, body);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      _showSuccessDialog(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create staff account'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Map<String, dynamic> _buildBody() {
    final base = {
      'fullName': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'facilityId': _selectedFacility!.id,
    };
    if (_selectedRole == 'CHW') {
      return {
        ...base,
        'employeeCode': _codeCtrl.text.trim(),
        'assignedVillage': _villageCtrl.text.trim(),
        'assignedSector': _sectorCtrl.text.trim(),
      };
    } else if (_selectedRole == 'FACILITY_PROVIDER') {
      return {
        ...base,
        if (_specCtrl.text.isNotEmpty) 'specialization': _specCtrl.text.trim(),
        if (_licenseCtrl.text.isNotEmpty) 'licenseNumber': _licenseCtrl.text.trim(),
      };
    } else {
      return {
        ...base,
        'district': _districtCtrl.text.trim(),
      };
    }
  }

  void _showSuccessDialog(StaffCreatedModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Account Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.fullName} has been registered.'),
            const SizedBox(height: 16),
            const Text(
              'Temporary Password',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      result.temporaryPassword ?? '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (result.temporaryPassword != null)
                    IconButton(
                      icon: const Icon(Icons.copy,
                          color: AppColors.primaryDark),
                      tooltip: 'Copy to clipboard',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: result.temporaryPassword!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Temporary password copied'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this securely. They must change it on first login.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // back to dashboard
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(adminFacilitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Staff Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: facilities.when(
            loading: () =>
                const AppLoader(message: 'Loading facilities...'),
            error: (_, __) => ErrorView(
              message: 'Could not load facilities',
              onRetry: () => ref.invalidate(adminFacilitiesProvider),
            ),
            data: (facilityList) => AbsorbPointer(
              absorbing: _isSubmitting,
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role selector
                    const _SectionLabel(label: 'Role'),
                    const SizedBox(height: 10),
                    ..._roles.map((r) => _RoleOption(
                          label: r.$1,
                          role: r.$2,
                          icon: r.$3,
                          selected: _selectedRole == r.$2,
                          onTap: () =>
                              setState(() => _selectedRole = r.$2),
                        )),

                    const SizedBox(height: 24),

                    // Basic info
                    const _SectionLabel(label: 'Personal Information'),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: Validators.required,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      action: TextInputAction.next,
                    ),

                    const SizedBox(height: 24),

                    // Facility picker
                    const _SectionLabel(label: 'Facility'),
                    const SizedBox(height: 10),
                    _FacilityPicker(
                      facilities: facilityList,
                      selected: _selectedFacility,
                      onSelect: (f) =>
                          setState(() => _selectedFacility = f),
                    ),

                    const SizedBox(height: 24),

                    // Role-specific fields
                    const _SectionLabel(label: 'Role Details'),
                    const SizedBox(height: 12),
                    if (_selectedRole == 'CHW') ...[
                      _Field(
                        controller: _codeCtrl,
                        label: 'Employee Code',
                        icon: Icons.badge_outlined,
                        validator: Validators.required,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _villageCtrl,
                        label: 'Assigned Village',
                        icon: Icons.location_on_outlined,
                        validator: Validators.required,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _sectorCtrl,
                        label: 'Assigned Sector',
                        icon: Icons.map_outlined,
                        validator: Validators.required,
                        action: TextInputAction.done,
                      ),
                    ] else if (_selectedRole == 'FACILITY_PROVIDER') ...[
                      _Field(
                        controller: _specCtrl,
                        label: 'Specialization (optional)',
                        icon: Icons.medical_information_outlined,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _licenseCtrl,
                        label: 'License Number (optional)',
                        icon: Icons.card_membership_outlined,
                        action: TextInputAction.done,
                      ),
                    ] else ...[
                      _Field(
                        controller: _districtCtrl,
                        label: 'District',
                        icon: Icons.location_city_outlined,
                        validator: Validators.required,
                        action: TextInputAction.done,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submit(facilityList),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────


class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction action;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: AppColors.textHint, size: 20),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String role;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.role,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selected ? AppColors.primary : AppColors.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FacilityPicker extends StatelessWidget {
  final List<FacilityModel> facilities;
  final FacilityModel? selected;
  final void Function(FacilityModel) onSelect;

  const _FacilityPicker({
    required this.facilities,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const Text('No facilities available',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: facilities
          .map(
            (f) => GestureDetector(
              onTap: () => onSelect(f),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected?.id == f.id
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected?.id == f.id
                        ? AppColors.primary
                        : AppColors.divider,
                    width: selected?.id == f.id ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected?.id == f.id
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected?.id == f.id
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${f.district} — ${f.location}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (selected?.id == f.id)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
