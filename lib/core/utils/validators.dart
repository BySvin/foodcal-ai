/// Shared form-field validators returning a user-facing error string, or
/// null when the value is valid — matches Flutter's TextFormField.validator.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  static String? ageRange(String? value, {int min = 13, int max = 120}) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid age';
    if (parsed < min || parsed > max) return 'Age must be between $min and $max';
    return null;
  }
}
