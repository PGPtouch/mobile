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
  String get unknown => 'Unknown';

  @override
  String deviceRole(String role) {
    return 'Device Role: $role';
  }

  @override
  String runError(String error) {
    return 'Error: $error';
  }

  @override
  String runFailureReason(String reason) {
    return 'Failure: $reason';
  }

  @override
  String runAdditionalInfo(String info) {
    return '($info)';
  }

  @override
  String get noDetails => 'No details';

  @override
  String get stopRun => 'Stop run';

  @override
  String get discardRun => 'Discard run';

  @override
  String get newRun => 'New run';

  @override
  String get goButton => 'Go!';

  @override
  String get selectIdentity => 'Select an Identity';

  @override
  String get nfcUnavailableHint =>
      'NFC seems to not be available on this device, but required for PGPtouch to work properly.';

  @override
  String get bluetoothUnavailableHint =>
      'Bluetooth seems to not be available on this device, but required for PGPtouch to work properly.';

  @override
  String get permissionsRequiredHint =>
      'There are still device permissions you need to grant for PGPtouch to work properly. Click here to do so.';

  @override
  String get nfcDisabledHint =>
      'NFC is not enabled, but required for PGPtouch to work properly. Click here to enable it.';

  @override
  String get bluetoothDisabledHint =>
      'Bluetooth is not enabled, but required for PGPtouch to work properly. Click here to enable it.';

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
  String get passphraseInputRemember => 'Remember using Vault';

  @override
  String get passphraseInputRememberDescription =>
      'This will store the passphrase on your device so you don’t have to enter it again.';

  @override
  String get passphraseInputSkip => 'Skip';

  @override
  String get passphraseInputContinue => 'Continue';

  @override
  String get backupCodeInputPrompt =>
      'The selected file is a Backup File, so you need the designated 24 character backup code to proceed.';

  @override
  String get backupCodeInputWrong => 'Wrong backup code.';

  @override
  String get backupCodeShowPrompt =>
      'The following 24 character backup code is needed to use the Backup File later on. Store it securely in a separate location away from the Backup File.';

  @override
  String get backupCodeShowCopy => 'Copy';

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
  String get identityDetailsHeadline => 'Details';

  @override
  String get identityCreation => 'Creation';

  @override
  String get identityExpiration => 'Expiration';

  @override
  String get identityExpirationNever => 'Never';

  @override
  String get identityExpired => 'Expired';

  @override
  String get identityRevoked => 'Revoked';

  @override
  String get identityRevocationReasonNoReason => 'No reason given';

  @override
  String get identityRevocationReasonKeySuperseded => 'Key superseded';

  @override
  String get identityRevocationReasonKeyCompromised => 'Key compromised';

  @override
  String get identityRevocationReasonKeyRetired => 'Has been retired';

  @override
  String get identityRevocationReasonUserIdInvalid => 'Invalid user ID';

  @override
  String get identityKeyStrength => 'Key strength';

  @override
  String get identityKeyAlgorithm => 'Key algorithm';

  @override
  String get identityKeyVersion => 'Key version';

  @override
  String get identityKeyId => 'Key ID';

  @override
  String get identityFingerprint => 'Fingerprint';

  @override
  String get identityPassphraseStored => 'Passphrase is stored';

  @override
  String get identityPassphraseNotStored => 'Passphrase is not stored';

  @override
  String get valueMissing => '–';

  @override
  String identityComment(String comment) {
    return '($comment)';
  }

  @override
  String get identityPassphraseRemembered => 'Remembered';

  @override
  String get identityActionsHeadline => 'Actions';

  @override
  String get identityExportKey => 'Export key';

  @override
  String get identityExportBackup => 'Export as backup';

  @override
  String get identityDeleteStoredPassphrase => 'Forget passphrase';

  @override
  String get identityDeleteKey => 'Delete';

  @override
  String get identityBackupExported => 'Backup exported.';

  @override
  String get identityBackupExportFailed => 'Failed to export backup.';

  @override
  String get identityKeyExported => 'Key exported.';

  @override
  String get identityKeyExportFailed => 'Failed to export key.';

  @override
  String get identityDeleted => 'Deleted.';

  @override
  String get identityDeleteFailed => 'Failed to delete.';

  @override
  String get identityStoredPassphraseRemoved => 'Stored passphrase removed.';

  @override
  String get identityStoredPassphraseRemoveFailed =>
      'Failed to remove stored passphrase.';

  @override
  String get identityUpdateKey => 'Update key';

  @override
  String identityPublicKeyUpdated(String origin) {
    return 'Updated successfully from: $origin';
  }

  @override
  String get identityPublicKeyUpdateNoSource => 'No source available.';

  @override
  String get identityPublicKeyUpdateFailed => 'Failed to update.';

  @override
  String get settingsHkpKeyServers => 'HKP key servers';

  @override
  String get settingsBetaFeatures => 'Beta features';

  @override
  String get settingsBetaFeaturesDescription =>
      'Opt-in to upcoming features whenever they become available.';

  @override
  String get settingsMiscellaneous => 'Miscellaneous';

  @override
  String get settingsClearSelectedIdentity => 'Clear selected identity';

  @override
  String get settingsClearSelectedIdentityDescription =>
      'Forgets the current selection for an identity. This does not delete the identity itself.';

  @override
  String get settingsClearSelectedIdentitySuccess =>
      'Cleared selected identity.';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsEnableTracking => 'Enable tracking';

  @override
  String get settingsEnableTrackingDescription =>
      'Allow the app to track anonymous usage data to improve its services.';

  @override
  String get settingsAboutApp => 'About this app';

  @override
  String get settingsExporting => 'Exporting';

  @override
  String get settingsExportingDescription =>
      'Importing files back into the app is done on the specific overview pages for contacts and identities respectively.';

  @override
  String get settingsExportAllContacts => 'All contacts';

  @override
  String get settingsExportAllIdentities => 'All identities';

  @override
  String get settingsExportAllIdentitiesBackup => 'All identities as backup';

  @override
  String get settingsExportInsecureTitle => 'Use insecure export?';

  @override
  String get settingsExportInsecureDescription =>
      'Exporting identities in this way is insecure, as anyone who gains access to the exported file can import all your private OpenPGP keys without your consent.\nUse the ‘Export identities as backup’ option for a safer method.';

  @override
  String get settingsExportNoContacts => 'No contacts to export.';

  @override
  String get settingsExportNoIdentities => 'No identities to export.';

  @override
  String get settingsExportContactsSuccess => 'Contacts exported successfully.';

  @override
  String get settingsExportContactsFailed => 'Failed to export contacts.';

  @override
  String get settingsExportIdentitiesSuccess =>
      'Identities exported successfully.';

  @override
  String get settingsExportIdentitiesFailed => 'Failed to export identities.';

  @override
  String get appBarUnlockTooltip => 'Unlock vault';

  @override
  String get appBarUnlockedTooltip => 'Vault unlocked';

  @override
  String get appBarSettingsTooltip => 'Settings';

  @override
  String get zxcvbnWarningStraightRows =>
      'Straight rows of keys are easy to guess';

  @override
  String get zxcvbnWarningShortKeyboardPatterns =>
      'Short keyboard patterns are easy to guess';

  @override
  String get zxcvbnWarningRepeatsSingleChar =>
      'Repeats like \"aaa\" are easy to guess';

  @override
  String get zxcvbnWarningRepeatsMultiChar =>
      'Repeats like \"abcabcabc\" are only slightly harder to guess than \"abc\"';

  @override
  String get zxcvbnWarningSequences =>
      'Sequences like abc or 6543 are easy to guess';

  @override
  String get zxcvbnWarningRecentYears => 'Recent years are easy to guess';

  @override
  String get zxcvbnWarningDates => 'Dates are often easy to guess';

  @override
  String get zxcvbnWarningTop10Password => 'This is a top-10 common password';

  @override
  String get zxcvbnWarningTop100Password => 'This is a top-100 common password';

  @override
  String get zxcvbnWarningVeryCommonPassword =>
      'This is a very common password';

  @override
  String get zxcvbnWarningSimilarToCommonPassword =>
      'This is similar to a commonly used password';

  @override
  String get zxcvbnWarningWordByItself => 'A word by itself is easy to guess';

  @override
  String get zxcvbnWarningNamesByThemselves =>
      'Names and surnames by themselves are easy to guess';

  @override
  String get zxcvbnWarningCommonNames =>
      'Common names and surnames are easy to guess';

  @override
  String get createIdentityTitle => 'New identity';

  @override
  String get createIdentityCreate => 'Create';

  @override
  String get createIdentityCreated => 'The identity was created successfully.';

  @override
  String get createIdentityHint =>
      'You need to set a passphrase and add at least one User ID to proceed.';

  @override
  String get createIdentityPassphraseSet => 'Set successfully';

  @override
  String get createIdentityPassphraseDialogTitle => 'Set passphrase';

  @override
  String get createIdentityPassphraseDialogDescription =>
      'You’ll need it to unlock the key, so every time you use it in PGPtouch.';

  @override
  String createIdentityPassphraseInsecure(String guesses) {
    return 'Insecure passphrase. An attacker would need an average of $guesses guesses.';
  }

  @override
  String get createIdentityExpirationRemoveTooltip => 'Remove expiration';

  @override
  String get createIdentityUserIdsHeadline => 'User IDs';

  @override
  String get createIdentityUserIdRemoveTooltip => 'Remove User ID';

  @override
  String get createIdentityUserIdAdd => 'Add User ID';

  @override
  String get createIdentityAdvancedHeadline => 'Advanced';

  @override
  String get createIdentityAlgorithmTitle => 'Algorithm';

  @override
  String get createIdentityAlgorithmDialogTitle => 'Set algorithm';

  @override
  String get createIdentityAlgorithmRecommendedTooltip =>
      'This is the recommended modern algorithm type.';

  @override
  String get createIdentityRsaKeySizeTitle => 'RSA Key Size';

  @override
  String get createIdentityRsaKeySizeDialogTitle => 'Set RSA key size';

  @override
  String get createIdentityRsaKeySizeNormal => 'Normal';

  @override
  String get createIdentityRsaKeySizeMedium => 'Medium';

  @override
  String get createIdentityRsaKeySizeHigh => 'High';

  @override
  String get createIdentityAllowKeyEncryptionTitle => 'Allow key encryption';

  @override
  String get createIdentityAllowKeyEncryptionDescription =>
      'If enabled, the key can later be used for encryption after export.';

  @override
  String get userIdDialogTitleNew => 'New User ID';

  @override
  String get userIdDialogTitleEdit => 'Edit User ID';

  @override
  String get userIdNameLabel => 'Name';

  @override
  String get userIdCommentLabel => 'Comment';

  @override
  String get userIdCommentHint => 'At work';

  @override
  String get userIdEmailLabel => 'Email';

  @override
  String get userIdSubmit => 'Submit';

  @override
  String get userIdEmailEmpty => 'Email cannot be empty.';

  @override
  String get userIdEmailMissingAt => 'Email must contain ‘@’.';

  @override
  String get userIdEmailTooShort => 'Email must be at least 3 characters long.';

  @override
  String get userIdCommentInvalidCharacter => 'Comment cannot contain ‘)’.';

  @override
  String get userIdInvalid => 'Invalid User ID.';
}
