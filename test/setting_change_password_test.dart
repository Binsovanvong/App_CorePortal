import 'package:flutter_test/flutter_test.dart';

bool validateNewPassword({
  required String password,
  required String oldPassword,
  String username = '',
}) {
  if (password.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
  if (!RegExp(r'[a-z]').hasMatch(password)) return false;
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  if (!RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:<>?\/]').hasMatch(password)) return false;
  if (username.isNotEmpty && password.toLowerCase().contains(username.toLowerCase())) return false;
  if (password == oldPassword) return false;
  return true;
}

String extractErrorMessage(dynamic errorData, {String defaultMessage = 'Default error'}) {
  if (errorData is Map) {
    final detail = errorData['detail'] ??
        errorData['message'] ??
        errorData['error_description'] ??
        errorData['error'];
    if (detail != null) {
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        } else {
          return detail.map((i) => i.toString()).join(", ");
        }
      } else if (detail.toString().isNotEmpty) {
        return detail.toString();
      }
    }
  }
  return defaultMessage;
}

void main() {
  group('Setting Change Password Policy & Validation Tests', () {
    test('Valid strong password passes validation', () {
      final isValid = validateNewPassword(
        password: 'ValidStrongPass123!',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isTrue);
    });

    test('Short password (< 8 chars) fails validation', () {
      final isValid = validateNewPassword(
        password: 'Aa1!',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password without uppercase fails validation', () {
      final isValid = validateNewPassword(
        password: 'lowercaseonly123!',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password without lowercase fails validation', () {
      final isValid = validateNewPassword(
        password: 'UPPERCASEONLY123!',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password without numbers fails validation', () {
      final isValid = validateNewPassword(
        password: 'NoNumbersHere!@#',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password without special characters fails validation', () {
      final isValid = validateNewPassword(
        password: 'NoSpecialChars1234',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password containing username fails validation', () {
      final isValid = validateNewPassword(
        password: 'SovannSecretPass123!',
        oldPassword: 'OldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Password equal to old password fails validation', () {
      final isValid = validateNewPassword(
        password: 'SameOldPassword123!',
        oldPassword: 'SameOldPassword123!',
        username: 'sovann',
      );
      expect(isValid, isFalse);
    });

    test('Dynamic error parsing extracts "detail" from backend payload', () {
      final errorPayload = {'detail': 'Request validation failed'};
      final message = extractErrorMessage(errorPayload);
      expect(message, equals('Request validation failed'));
    });

    test('Dynamic error parsing extracts "message" from backend payload', () {
      final errorPayload = {'message': 'New password cannot match old password'};
      final message = extractErrorMessage(errorPayload);
      expect(message, equals('New password cannot match old password'));
    });

    test('Dynamic error parsing falls back to default if payload has no detail/message', () {
      final errorPayload = {'unexpected': 'structure'};
      final message = extractErrorMessage(errorPayload, defaultMessage: 'Fallback error');
      expect(message, equals('Fallback error'));
    });

    test('Dynamic error parsing extracts msg from FastAPI validation list', () {
      final errorPayload = {
        'detail': [
          {'loc': ['body', 'username'], 'msg': 'Field required', 'type': 'missing'}
        ]
      };
      final message = extractErrorMessage(errorPayload);
      expect(message, equals('Field required'));
    });
  });
}
