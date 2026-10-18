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
      'Android’s Tap to share could not be blocked. Turn it off in Settings > Google > Quick Share > Tap to share, or taps may open the contact-share popup.';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navStartRun => 'Start run';

  @override
  String get navIdentities => 'Identities';

  @override
  String get vaultUnlockTitle => 'Unlock vault';

  @override
  String get vaultUnlockSubtitle =>
      'Verify your identity to unlock your personal vault and start using PGPtouch.';

  @override
  String get vaultUnlockKeepLocked => 'Keep locked';

  @override
  String get vaultUnlockDeviceReauthRequiredTitle =>
      'Device reauthentication required';

  @override
  String get vaultUnlockDeviceReauthRequiredMessage =>
      'Android couldn’t access the vault’s secure key. This may happen if the device needs to be reauthenticated.';

  @override
  String get vaultUnlockDeviceReauthRequiredStep1 => 'Lock your phone';

  @override
  String get vaultUnlockDeviceReauthRequiredStep2 => 'Unlock your phone';

  @override
  String get vaultUnlockDeviceReauthRequiredStep3 => 'Try again';

  @override
  String get addContactSourceSearch => 'Search online';

  @override
  String get addContactSourceClipboard => 'Paste from clipboard';

  @override
  String get addContactSourceFile => 'Import from file';

  @override
  String get addIdentitySourceCreate => 'Create new';

  @override
  String get passphraseInputWrong => 'Wrong passphrase.';

  @override
  String get passphraseInputPrompt =>
      'You need to enter a passphrase for the following identities:';

  @override
  String enquote(String text) {
    return '“$text”';
  }

  @override
  String get passphraseInputLabel => 'Passphrase';

  @override
  String get passphraseInputHelper =>
      'This is the passphrase you entered while creating the identity. Make sure it matches exactly.';

  @override
  String get passphraseInputRemember => 'Remember using Vault';

  @override
  String get passphraseInputRememberDescription =>
      'This will store the passphrase on your device so you don’t have to enter it again.';

  @override
  String get passphraseInputSkip => 'Skip';

  @override
  String get passphraseInputContinue => 'Continue';

  @override
  String get addContactClipboardEmpty => 'Clipboard is empty.';

  @override
  String get addContactClipboardReadFailed =>
      'Failed to read clipboard content.';

  @override
  String addContactClipboardReadKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys',
      one: '$count key',
    );
    return 'Read $_temp0 from clipboard.';
  }

  @override
  String get addIdentityClipboardReadKey => 'Read key from clipboard.';

  @override
  String get addContactFileImport => 'Import';

  @override
  String get addContactFileFailed => 'Failed to read file.';

  @override
  String get addContactFileReadFailed => 'Failed to read file content.';

  @override
  String addContactFileReadKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys',
      one: '$count key',
    );
    return 'Read $_temp0 from file.';
  }

  @override
  String get addIdentityFileReadKey => 'Read key from file.';

  @override
  String get addContactSearchLabel => 'Email Address / Identity';

  @override
  String get addContactSearchHint => 'user@example.net';

  @override
  String get addContactSearchHelper =>
      'This usually is equal to the person’s primary email address.';

  @override
  String get addContactSearchQueryTooShort =>
      'Query must be at least 3 characters long.';

  @override
  String get addContactSearchQueryInvalidEmail =>
      'Query must be a valid email address.';

  @override
  String get addContactSearchNoKeys =>
      'No keys found for the given email address.';

  @override
  String get addContactSearchFailed => 'Failed to fetch keys.';

  @override
  String get addContactSearchResultUnusable => 'Key cannot be used here.';

  @override
  String get addContactSearchResultExpired => 'It has already expired.';

  @override
  String get addContactSearchResultRevoked => 'It has been revoked.';

  @override
  String get addContactSearchResultUnreadable =>
      'This app is having trouble reading it.';

  @override
  String get addContactSearchResultNotInPrimaryTooltip =>
      'This key is not present in the primary search result.';

  @override
  String get addContactSearchResultDiffersTooltip =>
      'This key is different from its counterpart in the primary search result. It may be outdated.';

  @override
  String get addContactSearchResultPreferredTooltip =>
      'This is the preferred search result. You should probably pick this key before any others.';

  @override
  String get addContactSearchResultIdentityVerifiedTooltip =>
      'This key server verifies that uploaded keys belong to their listed email addresses.';

  @override
  String get addContactSearchAdded => 'Added 1 key from search.';

  @override
  String get keyFetchOriginWebKeyDirectoryAdvanced =>
      'Web Key Directory (Advanced)';

  @override
  String get keyFetchOriginWebKeyDirectoryDirect =>
      'Web Key Directory (Direct)';

  @override
  String get keyFetchOriginHkpKeyServer => 'HKP Key Server';

  @override
  String keyFetchKeyserverTitle(String name) {
    return '$name Keyserver';
  }

  @override
  String get contactsEmpty => 'No contacts yet.';

  @override
  String get contactsAddTooltip => 'Add';

  @override
  String get identitiesUnlock => 'Unlock!';

  @override
  String get identitiesEmpty => 'No identities yet.\nStart by creating one!';

  @override
  String get settingsHkpKeyServers => 'HKP key servers';

  @override
  String get settingsMiscellaneous => 'Miscellaneous';

  @override
  String get settingsDeleteStoredPassphrases => 'Delete stored passphrases';

  @override
  String get settingsAboutApp => 'About this app';

  @override
  String get appBarUnlockTooltip => 'Unlock vault';

  @override
  String get appBarUnlockedTooltip => 'Vault unlocked';

  @override
  String get appBarSettingsTooltip => 'Settings';
}
