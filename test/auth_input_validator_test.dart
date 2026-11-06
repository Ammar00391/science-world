import 'package:flutter_test/flutter_test.dart';
import 'package:science_world/features/auth/data/auth_input_validator.dart';

void main() {
  group('AuthInputValidator', () {
    test('accepts a valid email and rejects malformed addresses', () {
      expect(AuthInputValidator.isValidEmail('student@example.com'), isTrue);
      expect(AuthInputValidator.isValidEmail(' student@example.com '), isTrue);
      expect(AuthInputValidator.isValidEmail('student@'), isFalse);
      expect(AuthInputValidator.isValidEmail('student example.com'), isFalse);
    });

    test('validates a full name', () {
      expect(AuthInputValidator.isValidFullName('Ali Ahmad'), isTrue);
      expect(AuthInputValidator.isValidFullName(' A '), isFalse);
      expect(AuthInputValidator.isValidFullName('   '), isFalse);
    });

    test('accepts international phone numbers', () {
      expect(AuthInputValidator.isValidPhone('+90 538 956 7265'), isTrue);
      expect(AuthInputValidator.isValidPhone('0090-538-956-7265'), isTrue);
      expect(AuthInputValidator.isValidPhone('12345'), isFalse);
      expect(AuthInputValidator.isValidPhone('phone-number'), isFalse);
    });

    test('requires passwords to contain at least eight characters', () {
      expect(AuthInputValidator.isValidPassword('science88'), isTrue);
      expect(AuthInputValidator.isValidPassword('short7'), isFalse);
    });
  });
}
