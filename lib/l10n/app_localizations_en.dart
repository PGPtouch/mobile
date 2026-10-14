// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PGPtouch';

  @override
  String get contactModeInitializing => 'Initializing...';

  @override
  String get contactModeTapOther => 'Tap device';

  @override
  String get contactModeHoldOther => 'Hold...';

  @override
  String get transactionSuccess => 'Success!';

  @override
  String get transactionFailure => 'Failure';

  @override
  String get unknown => 'Unknown';

  @override
  String deviceRole(String role) {
    return 'Device Role: $role';
  }

  @override
  String transactionResult(String result) {
    return 'Result: $result';
  }

  @override
  String transactionError(String error) {
    return 'Error: $error';
  }

  @override
  String transactionFailureReason(String reason) {
    return 'Failure: $reason';
  }

  @override
  String transactionAdditionalInfo(String info) {
    return '($info)';
  }

  @override
  String get noDetails => 'No details';

  @override
  String get stopTransaction => 'Stop transaction';

  @override
  String get restartTransaction => 'Restart transaction';

  @override
  String get generateKeys => 'Generate keys';

  @override
  String get grantPermissions => 'Grant permissions';

  @override
  String get enableNfc => 'Enable NFC';

  @override
  String get enableBluetooth => 'Enable Bluetooth';

  @override
  String get startTransaction => 'Start transaction';

  @override
  String get nfcNotAvailable => 'NFC is not available on this device.';

  @override
  String get bluetoothNotAvailable =>
      'Bluetooth is not available on this device.';

  @override
  String get tapToShareInterferingTitle => 'Tap to share is interfering';

  @override
  String get tapToShareInterferingMessage =>
      'Android\'s Tap to share could not be blocked. Turn it off in Settings > Google > Quick Share > Tap to share, or taps may open the contact-share popup.';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navStartRun => 'Start run';

  @override
  String get navIdentities => 'Identities';
}
