/// Single source of truth for input-format rules on the mobile app. Mirrors
/// the backend's com.nelly.hivtbmonitoringsystem.validation package exactly
/// (same regex, same messages) so a value accepted/rejected here is
/// accepted/rejected identically by the API — this class only gives the
/// CHW/clinical user feedback before they submit; the backend remains the
/// real gate against bad data. Keep all three (backend, web, mobile) in
/// sync if a rule changes.
abstract class Validators {
  static final RegExp _rwandaPhone = RegExp(r'^(07\d{8}|\+2507\d{8})$');
  static final RegExp _rwandaNationalId = RegExp(r'^\d{16}$');
  static final RegExp _employeeCode = RegExp(r'^[A-Za-z0-9-]{3,50}$');

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email address is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address (e.g. name@example.com)';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Rwanda mobile number: 10 digits starting with 07, or +250 followed by
  /// 7 and 8 digits. Empty is treated as valid — pair with [required] for
  /// mandatory phone fields.
  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!_rwandaPhone.hasMatch(v)) {
      return 'Phone number must be 10 digits starting with 07 (e.g. 0788123456), or start with +250';
    }
    return null;
  }

  static String? requiredPhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    return phone(value);
  }

  /// Rwanda national ID: exactly 16 digits. Empty is treated as valid —
  /// national ID is optional on most patient records.
  static String? nationalId(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!_rwandaNationalId.hasMatch(v)) return 'National ID must be exactly 16 digits';
    return null;
  }

  static String? employeeCode(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Employee code is required';
    if (!_employeeCode.hasMatch(v)) {
      return 'Employee code may only contain letters, numbers, and hyphens (3-50 characters)';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'This field'} must be at most $max characters';
    }
    return null;
  }

  static String? dateNotFuture(DateTime? value, [String? fieldName]) {
    if (value == null) return null;
    if (value.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Date'} cannot be in the future';
    }
    return null;
  }

  static String? positiveInt(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return '${fieldName ?? 'Value'} is required';
    final n = int.tryParse(value);
    if (n == null || n < 0) return 'Enter a valid positive number';
    return null;
  }
}
