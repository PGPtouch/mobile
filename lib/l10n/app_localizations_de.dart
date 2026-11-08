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
  String get unknown => 'Unbekannt';

  @override
  String deviceRole(String role) {
    return 'Geräterolle: $role';
  }

  @override
  String runError(String error) {
    return 'Fehler: $error';
  }

  @override
  String runFailureReason(String reason) {
    return 'Fehlschlag: $reason';
  }

  @override
  String runAdditionalInfo(String info) {
    return '($info)';
  }

  @override
  String get noDetails => 'Keine Details';

  @override
  String get stopRun => 'Durchlauf beenden';

  @override
  String get discardRun => 'Durchlauf verwerfen';

  @override
  String get newRun => 'Neuer Durchlauf';

  @override
  String get goButton => 'Los!';

  @override
  String get selectIdentity => 'Identität auswählen';

  @override
  String get nfcUnavailableHint =>
      'NFC ist auf diesem Gerät nicht verfügbar, wird aber für die korrekte Funktion der App benötigt.';

  @override
  String get bluetoothUnavailableHint =>
      'Bluetooth ist auf diesem Gerät nicht verfügbar, wird aber für die korrekte Funktion der App benötigt.';

  @override
  String get permissionsRequiredHint =>
      'Du musst noch Geräteberechtigungen erteilen, damit PGPtouch korrekt funktioniert. Tippe dafür hier.';

  @override
  String get nfcDisabledHint =>
      'NFC ist deaktiviert, wird aber für die korrekte Funktion der App benötigt. Tippe zum Aktivieren hier.';

  @override
  String get bluetoothDisabledHint =>
      'Bluetooth ist deaktiviert, wird aber für die korrekte Funktion der App benötigt. Tippe zum Aktivieren hier.';

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
  String get identityKeyAlgorithm => 'Schlüsselalgorithmus';

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
  String get identityDeleteStoredPassphrase => 'Passphrase vergessen';

  @override
  String get identityDeleteKey => 'Löschen';

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
  String get settingsBetaFeatures => 'Beta-Funktionen';

  @override
  String get settingsBetaFeaturesDescription =>
      'Neue Funktionen testen, sobald sie verfügbar sind.';

  @override
  String get settingsMiscellaneous => 'Sonstiges';

  @override
  String get settingsClearSelectedIdentity =>
      'Ausgewählte Identität zurücksetzen';

  @override
  String get settingsClearSelectedIdentityDescription =>
      'Setzt die aktuelle Auswahl einer Identität zurück. Die Identität selbst wird dabei nicht gelöscht.';

  @override
  String get settingsClearSelectedIdentitySuccess =>
      'Ausgewählte Identität zurückgesetzt.';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsEnableTracking => 'Tracking aktivieren';

  @override
  String get settingsEnableTrackingDescription =>
      'Erlaubt der App, anonyme Nutzungsdaten zu erfassen, um ihre Dienste zu verbessern.';

  @override
  String get settingsAboutApp => 'Über diese App';

  @override
  String get settingsExporting => 'Exportieren';

  @override
  String get settingsExportingDescription =>
      'Dateien können auf den Übersichtsseiten für Kontakte und Identitäten wieder in die App importiert werden.';

  @override
  String get settingsExportAllContacts => 'Alle Kontakte';

  @override
  String get settingsExportAllIdentities => 'Alle Identitäten';

  @override
  String get settingsExportAllIdentitiesBackup =>
      'Alle Identitäten als Sicherung';

  @override
  String get settingsExportInsecureTitle => 'Unsicheren Export verwenden?';

  @override
  String get settingsExportInsecureDescription =>
      'Das Exportieren von Identitäten auf diese Weise ist unsicher, da jeder, der Zugriff auf die exportierte Datei erhält, alle deine privaten OpenPGP-Schlüssel ohne deine Zustimmung importieren kann.\nVerwende ‚Identitäten als Sicherung exportieren‘ für eine sicherere Methode.';

  @override
  String get settingsExportNoContacts => 'Keine Kontakte zum Exportieren.';

  @override
  String get settingsExportNoIdentities => 'Keine Identitäten zum Exportieren.';

  @override
  String get settingsExportContactsSuccess =>
      'Kontakte erfolgreich exportiert.';

  @override
  String get settingsExportContactsFailed =>
      'Kontakte konnten nicht exportiert werden.';

  @override
  String get settingsExportIdentitiesSuccess =>
      'Identitäten erfolgreich exportiert.';

  @override
  String get settingsExportIdentitiesFailed =>
      'Identitäten konnten nicht exportiert werden.';

  @override
  String get appBarUnlockTooltip => 'Tresor entsperren';

  @override
  String get appBarUnlockedTooltip => 'Tresor entsperrt';

  @override
  String get appBarSettingsTooltip => 'Einstellungen';

  @override
  String get zxcvbnWarningStraightRows =>
      'Gerade Tastenreihen sind leicht zu erraten';

  @override
  String get zxcvbnWarningShortKeyboardPatterns =>
      'Kurze Tastaturmuster sind leicht zu erraten';

  @override
  String get zxcvbnWarningRepeatsSingleChar =>
      'Wiederholungen wie „aaa“ sind leicht zu erraten';

  @override
  String get zxcvbnWarningRepeatsMultiChar =>
      'Wiederholungen wie „abcabcabc“ sind nur geringfügig schwerer zu erraten als „abc“';

  @override
  String get zxcvbnWarningSequences =>
      'Folgen wie abc oder 6543 sind leicht zu erraten';

  @override
  String get zxcvbnWarningRecentYears =>
      'Aktuelle Jahreszahlen sind leicht zu erraten';

  @override
  String get zxcvbnWarningDates => 'Datumsangaben sind oft leicht zu erraten';

  @override
  String get zxcvbnWarningTop10Password =>
      'Dies gehört zu den 10 häufigsten Passwörtern';

  @override
  String get zxcvbnWarningTop100Password =>
      'Dies gehört zu den 100 häufigsten Passwörtern';

  @override
  String get zxcvbnWarningVeryCommonPassword =>
      'Dies ist ein sehr häufig verwendetes Passwort';

  @override
  String get zxcvbnWarningSimilarToCommonPassword =>
      'Dies ähnelt einem häufig verwendeten Passwort';

  @override
  String get zxcvbnWarningWordByItself =>
      'Ein einzelnes Wort ist leicht zu erraten';

  @override
  String get zxcvbnWarningNamesByThemselves =>
      'Einzelne Vor- oder Nachnamen sind leicht zu erraten';

  @override
  String get zxcvbnWarningCommonNames =>
      'Häufige Vor- und Nachnamen sind leicht zu erraten';

  @override
  String get createIdentityTitle => 'Neue Identität';

  @override
  String get createIdentityCreate => 'Erstellen';

  @override
  String get createIdentityCreated =>
      'Die Identität wurde erfolgreich erstellt.';

  @override
  String get createIdentityHint =>
      'Zum Fortfahren musst du eine Passphrase festlegen und eine User-ID hinzufügen.';

  @override
  String get createIdentityPassphraseSet => 'Erfolgreich festgelegt';

  @override
  String get createIdentityPassphraseDialogTitle => 'Passphrase setzen';

  @override
  String get createIdentityPassphraseDialogDescription =>
      'Du benötigst sie, um den Schlüssel zu entsperren, also jedes Mal, wenn du ihn in PGPtouch verwendest.';

  @override
  String createIdentityPassphraseInsecure(String guesses) {
    return 'Unsichere Passphrase. Ein Angreifer würde durchschnittlich $guesses Versuche benötigen.';
  }

  @override
  String get createIdentityExpirationRemoveTooltip => 'Ablaufdatum entfernen';

  @override
  String get createIdentityUserIdsHeadline => 'User-IDs';

  @override
  String get createIdentityUserIdRemoveTooltip => 'User-ID entfernen';

  @override
  String get createIdentityUserIdAdd => 'User-ID hinzufügen';

  @override
  String get createIdentityAdvancedHeadline => 'Erweitert';

  @override
  String get createIdentityAlgorithmTitle => 'Algorithmus';

  @override
  String get createIdentityAlgorithmDialogTitle => 'Algorithmus setzen';

  @override
  String get createIdentityAlgorithmRecommendedTooltip =>
      'Dies ist der empfohlene moderne Algorithmus.';

  @override
  String get createIdentityRsaKeySizeTitle => 'RSA-Schlüsselgröße';

  @override
  String get createIdentityRsaKeySizeDialogTitle => 'RSA-Schlüsselgröße setzen';

  @override
  String get createIdentityRsaKeySizeNormal => 'Normal';

  @override
  String get createIdentityRsaKeySizeMedium => 'Mittel';

  @override
  String get createIdentityRsaKeySizeHigh => 'Hoch';

  @override
  String get createIdentityAllowKeyEncryptionTitle =>
      'Schlüsselverschlüsselung erlauben';

  @override
  String get createIdentityAllowKeyEncryptionDescription =>
      'Wenn aktiviert, kann der Schlüssel nach dem Export später zum Verschlüsseln verwendet werden.';

  @override
  String get userIdDialogTitleNew => 'Neue User-ID';

  @override
  String get userIdDialogTitleEdit => 'User-ID bearbeiten';

  @override
  String get userIdNameLabel => 'Name';

  @override
  String get userIdCommentLabel => 'Kommentar';

  @override
  String get userIdCommentHint => 'Bei der Arbeit';

  @override
  String get userIdEmailLabel => 'E-Mail';

  @override
  String get userIdSubmit => 'Bestätigen';

  @override
  String get userIdEmailEmpty => 'Die E-Mail-Adresse darf nicht leer sein.';

  @override
  String get userIdEmailMissingAt =>
      'Die E-Mail-Adresse muss ein ‚@‘ enthalten.';

  @override
  String get userIdEmailTooShort =>
      'Die E-Mail-Adresse muss mindestens 3 Zeichen lang sein.';

  @override
  String get userIdCommentInvalidCharacter =>
      'Der Kommentar darf kein ‚)‘ enthalten.';

  @override
  String get userIdInvalid => 'Ungültige User-ID.';
}
