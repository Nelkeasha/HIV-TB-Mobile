abstract class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
      return 'Enter a valid email address';
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

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
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
