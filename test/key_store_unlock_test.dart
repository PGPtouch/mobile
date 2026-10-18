import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/database/key_store.dart';

void main() {
  group('isDeviceReauthRequired', () {
    test('detects the Keystore locked failure in the error details', () {
      final error = PlatformException(
        code: 'Exception encountered',
        message: 'Key mismatch after algorithm change (Invalid key)',
        details:
            'Caused by: android.security.keystore.UserNotAuthenticatedException: User not authenticated',
      );
      expect(isDeviceReauthRequired(error), isTrue);
    });

    test('ignores other errors', () {
      expect(
        isDeviceReauthRequired(
          PlatformException(code: 'x', message: 'Authentication canceled'),
        ),
        isFalse,
      );
      expect(isDeviceReauthRequired(StateError('x')), isFalse);
    });
  });
}
