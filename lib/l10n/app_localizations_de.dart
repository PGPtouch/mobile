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
  String get navContacts => 'Kontakte';

  @override
  String get navStartRun => 'Durchlauf starten';

  @override
  String get navIdentities => 'Identitäten';

  @override
  String get vaultUnlockTitle => 'Tresor entsperren';

  @override
  String get vaultUnlockSubtitle =>
      'Bestätige deine Identität, um deinen persönlichen Tresor zu entsperren und PGPtouch zu nutzen.';

  @override
  String get vaultUnlockKeepLocked => 'Gesperrt lassen';

  @override
  String get vaultUnlockDeviceReauthRequiredTitle =>
      'Geräte-Neuanmeldung erforderlich';

  @override
  String get vaultUnlockDeviceReauthRequiredMessage =>
      'Android konnte nicht auf den sicheren Schlüssel des Tresors zugreifen. Das kann passieren, wenn das Gerät neu authentifiziert werden muss.';

  @override
  String get vaultUnlockDeviceReauthRequiredStep1 => 'Sperre dein Handy';

  @override
  String get vaultUnlockDeviceReauthRequiredStep2 => 'Entsperre dein Handy';

  @override
  String get vaultUnlockDeviceReauthRequiredStep3 => 'Versuche es erneut';

  @override
  String get addContactSourceSearch => 'Online suchen';

  @override
  String get addContactSourceClipboard => 'Aus Zwischenablage einfügen';

  @override
  String get addContactSourceFile => 'Aus Datei importieren';

  @override
  String get addIdentitySourceCreate => 'Neue erstellen';

  @override
  String get passphraseInputWrong => 'Falsche Passphrase.';

  @override
  String get passphraseInputPrompt =>
      'Du musst eine Passphrase für die folgenden Identitäten eingeben:';

  @override
  String enquote(String text) {
    return '„$text“';
  }

  @override
  String get passphraseInputLabel => 'Passphrase';

  @override
  String get passphraseInputRemember => 'Im Tresor merken';

  @override
  String get passphraseInputRememberDescription =>
      'Die Passphrase wird auf dem Gerät gespeichert, damit du sie nicht erneut eingeben musst.';

  @override
  String get passphraseInputSkip => 'Überspringen';

  @override
  String get passphraseInputContinue => 'Weiter';

  @override
  String get backupCodeInputPrompt =>
      'Die ausgewählte Datei ist eine Sicherungsdatei, daher benötigst du den dazugehörigen 24-stelligen Sicherungscode, um fortzufahren.';

  @override
  String get backupCodeInputWrong => 'Falscher Sicherungscode.';

  @override
  String get backupCodeShowPrompt =>
      'Der folgende 24-stellige Sicherungscode wird benötigt, um die Sicherungsdatei später zu verwenden. Bewahre ihn sicher an einem separaten Ort auf.';

  @override
  String get backupCodeShowCopy => 'Kopieren';

  @override
  String get addContactClipboardEmpty => 'Die Zwischenablage ist leer.';

  @override
  String get addContactClipboardReadFailed =>
      'Inhalt der Zwischenablage konnte nicht gelesen werden.';

  @override
  String addContactClipboardReadKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schlüssel',
      one: '$count Schlüssel',
    );
    return '$_temp0 aus der Zwischenablage gelesen.';
  }

  @override
  String get addContactFileFailed => 'Datei konnte nicht gelesen werden.';

  @override
  String get addContactFileReadFailed =>
      'Dateiinhalt konnte nicht gelesen werden.';

  @override
  String addContactFileReadKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schlüssel',
      one: '$count Schlüssel',
    );
    return '$_temp0 aus der Datei gelesen.';
  }

  @override
  String get addContactSearchLabel => 'E-Mail-Adresse / Identität';

  @override
  String get addContactSearchHint => 'nutzer@example.net';

  @override
  String get addContactSearchHelper =>
      'Das ist normalerweise die primäre E-Mail-Adresse der jeweiligen Person.';

  @override
  String get addContactSearchQueryTooShort =>
      'Die Suchanfrage muss mindestens 3 Zeichen lang sein.';

  @override
  String get addContactSearchQueryInvalidEmail =>
      'Die Suchanfrage muss eine gültige E-Mail-Adresse sein.';

  @override
  String get addContactSearchNoKeys =>
      'Für die angegebene E-Mail-Adresse wurden keine Schlüssel gefunden.';

  @override
  String get addContactSearchFailed =>
      'Schlüssel konnten nicht abgerufen werden.';

  @override
  String get addContactSearchResultUnusable =>
      'Schlüssel kann hier nicht verwendet werden.';

  @override
  String get addContactSearchResultExpired => 'Er ist bereits abgelaufen.';

  @override
  String get addContactSearchResultRevoked => 'Er wurde widerrufen.';

  @override
  String get addContactSearchResultUnreadable =>
      'Diese App kann ihn nicht lesen.';

  @override
  String get addContactSearchResultNotInPrimaryTooltip =>
      'Dieser Schlüssel ist im primären Suchergebnis nicht enthalten.';

  @override
  String get addContactSearchResultDiffersTooltip =>
      'Dieser Schlüssel unterscheidet sich von seinem Gegenstück im primären Suchergebnis. Er könnte veraltet sein.';

  @override
  String get addContactSearchResultPreferredTooltip =>
      'Das ist das bevorzugte Suchergebnis. Du solltest diesen Schlüssel vermutlich vor allen anderen wählen.';

  @override
  String get addContactSearchResultIdentityVerifiedTooltip =>
      'Dieser Schlüsselserver prüft, ob hochgeladene Schlüssel zu den angegebenen E-Mail-Adressen gehören.';

  @override
  String get addContactSearchAdded => '1 Schlüssel aus der Suche hinzugefügt.';

  @override
  String get keyFetchOriginWebKeyDirectoryAdvanced =>
      'Web Key Directory (Erweitert)';

  @override
  String get keyFetchOriginWebKeyDirectoryDirect =>
      'Web Key Directory (Direkt)';

  @override
  String get keyFetchOriginHkpKeyServer => 'HKP-Schlüsselserver';

  @override
  String keyFetchKeyserverTitle(String name) {
    return '$name Schlüsselserver';
  }

  @override
  String get contactsEmpty => 'Noch keine Kontakte.';

  @override
  String get contactsAddTooltip => 'Hinzufügen';

  @override
  String get identitiesUnlock => 'Entsperren!';

  @override
  String get identitiesEmpty =>
      'Noch keine Identitäten.\nErstelle gleich eine!';

  @override
  String get identityDetailsHeadline => 'Details';

  @override
  String get identityCreation => 'Erstellung';

  @override
  String get identityExpiration => 'Ablauf';

  @override
  String get identityExpirationNever => 'Nie';

  @override
  String get identityExpired => 'Abgelaufen';

  @override
  String get identityRevoked => 'Widerrufen';

  @override
  String get identityRevocationReasonNoReason => 'Kein Grund angegeben';

  @override
  String get identityRevocationReasonKeySuperseded => 'Schlüssel ersetzt';

  @override
  String get identityRevocationReasonKeyCompromised =>
      'Schlüssel kompromittiert';

  @override
  String get identityRevocationReasonKeyRetired =>
      'Wurde außer Betrieb genommen';

  @override
  String get identityRevocationReasonUserIdInvalid => 'Ungültige Benutzer-ID';

  @override
  String get identityKeyStrength => 'Schlüsselstärke';

  @override
  String get identityKeyVersion => 'Schlüsselversion';

  @override
  String get identityKeyId => 'Schlüssel-ID';

  @override
  String get identityFingerprint => 'Fingerabdruck';

  @override
  String get identityPassphraseStored => 'Passphrase ist gespeichert';

  @override
  String get identityPassphraseNotStored => 'Passphrase ist nicht gespeichert';

  @override
  String get valueMissing => '–';

  @override
  String identityComment(String comment) {
    return '($comment)';
  }

  @override
  String get identityPassphraseRemembered => 'Gemerkt';

  @override
  String get identityActionsHeadline => 'Aktionen';

  @override
  String get identityExportKey => 'Schlüssel exportieren';

  @override
  String get identityExportBackup => 'Als Sicherung exportieren';

  @override
  String get identityDeleteKey => 'Schlüssel löschen';

  @override
  String get identityDeleteStoredPassphrase =>
      'Gespeicherte Passphrase löschen';

  @override
  String get identityBackupExported => 'Sicherung exportiert.';

  @override
  String get identityBackupExportFailed =>
      'Sicherung konnte nicht exportiert werden.';

  @override
  String get identityKeyExported => 'Schlüssel exportiert.';

  @override
  String get identityKeyExportFailed =>
      'Schlüssel konnte nicht exportiert werden.';

  @override
  String get identityDeleted => 'Gelöscht.';

  @override
  String get identityDeleteFailed => 'Löschen fehlgeschlagen.';

  @override
  String get identityStoredPassphraseRemoved =>
      'Gespeicherte Passphrase entfernt.';

  @override
  String get identityStoredPassphraseRemoveFailed =>
      'Gespeicherte Passphrase konnte nicht entfernt werden.';

  @override
  String get identityUpdatePublicKey => 'Öffentlichen Schlüssel aktualisieren';

  @override
  String get identityUpdateKey => 'Schlüssel aktualisieren';

  @override
  String identityPublicKeyUpdated(String origin) {
    return 'Erfolgreich aktualisiert von: $origin';
  }

  @override
  String get identityPublicKeyUpdateNoSource => 'Keine Quelle verfügbar.';

  @override
  String get identityPublicKeyUpdateFailed => 'Aktualisierung fehlgeschlagen.';

  @override
  String get settingsHkpKeyServers => 'HKP-Schlüsselserver';

  @override
  String get settingsMiscellaneous => 'Sonstiges';

  @override
  String get settingsDeleteStoredPassphrases =>
      'Gespeicherte Passphrasen löschen';

  @override
  String get settingsAboutApp => 'Über diese App';

  @override
  String get appBarUnlockTooltip => 'Tresor entsperren';

  @override
  String get appBarUnlockedTooltip => 'Tresor entsperrt';

  @override
  String get appBarSettingsTooltip => 'Einstellungen';
}
