/// Small, deterministic input validators shared by auth screens and tests.
class AuthInputValidator {
  AuthInputValidator._();

  static bool isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  static bool isValidFullName(String value) => value.trim().length >= 2;

  /// Accepts international numbers such as +90 538 956 7265.
  static bool isValidPhone(String value) {
    final phone = value.trim();
    if (!RegExp(r'^\+?[0-9().\s-]+$').hasMatch(phone)) return false;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  static bool isValidPassword(String value) => value.length >= 8;
}
