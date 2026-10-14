// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PGPtouch';

  @override
  String get contactModeInitializing => 'Initialisieren...';

  @override
  String get contactModeTapOther => 'Gerät antippen';

  @override
  String get contactModeHoldOther => 'Halten...';

  @override
  String get transactionSuccess => 'Erfolgreich!';

  @override
  String get transactionFailure => 'Fehlgeschlagen';

  @override
  String get unknown => 'Unbekannt';

  @override
  String deviceRole(String role) {
    return 'Geräterolle: $role';
  }

  @override
  String transactionResult(String result) {
    return 'Ergebnis: $result';
  }

  @override
  String transactionError(String error) {
    return 'Fehler: $error';
  }

  @override
  String transactionFailureReason(String reason) {
    return 'Fehlschlag: $reason';
  }

  @override
  String transactionAdditionalInfo(String info) {
    return '($info)';
  }

  @override
  String get noDetails => 'Keine Details';

  @override
  String get stopTransaction => 'Transaktion beenden';

  @override
  String get restartTransaction => 'Transaktion neu starten';

  @override
  String get generateKeys => 'Schlüssel generieren';

  @override
  String get grantPermissions => 'Berechtigungen erteilen';

  @override
  String get enableNfc => 'NFC aktivieren';

  @override
  String get enableBluetooth => 'Bluetooth aktivieren';

  @override
  String get startTransaction => 'Transaktion starten';

  @override
  String get nfcNotAvailable => 'NFC ist auf diesem Gerät nicht verfügbar.';

  @override
  String get bluetoothNotAvailable =>
      'Bluetooth ist auf diesem Gerät nicht verfügbar.';

  @override
  String get tapToShareInterferingTitle => '„Tap to share“ stört';

  @override
  String get tapToShareInterferingMessage =>
      'Androids „Tap to share“ konnte nicht blockiert werden. Deaktiviere es unter Einstellungen > Google > Quick Share > Tap to share, da Antippen sonst das Popup zum Teilen von Kontakten öffnen kann.';

  @override
  String get navContacts => 'Kontakte';

  @override
  String get navStartRun => 'Durchlauf starten';

  @override
  String get navIdentities => 'Identitäten';
}
