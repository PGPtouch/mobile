import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'PGPtouch'**
  String get appTitle;

  /// Headline shown while the transaction is initializing
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get contactModeInitializing;

  /// Headline instructing the user to tap the other device
  ///
  /// In en, this message translates to:
  /// **'Tap device'**
  String get contactModeTapOther;

  /// Headline instructing the user to keep holding the devices together
  ///
  /// In en, this message translates to:
  /// **'Hold...'**
  String get contactModeHoldOther;

  /// Headline shown when the transaction finished successfully
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get transactionSuccess;

  /// Headline shown when the transaction did not finish successfully
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get transactionFailure;

  /// Fallback shown when a value is not known
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Label showing the role of this device in the transaction
  ///
  /// In en, this message translates to:
  /// **'Device Role: {role}'**
  String deviceRole(String role);

  /// Label showing the result of the transaction
  ///
  /// In en, this message translates to:
  /// **'Result: {result}'**
  String transactionResult(String result);

  /// Label showing the error mode of a failed transaction
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String transactionError(String error);

  /// Label showing the failure mode of a failed transaction
  ///
  /// In en, this message translates to:
  /// **'Failure: {reason}'**
  String transactionFailureReason(String reason);

  /// Additional details about a failed transaction, shown in parentheses
  ///
  /// In en, this message translates to:
  /// **'({info})'**
  String transactionAdditionalInfo(String info);

  /// Fallback shown when a failed transaction has no additional details
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// Button label to stop the current transaction
  ///
  /// In en, this message translates to:
  /// **'Stop transaction'**
  String get stopTransaction;

  /// Button label to restart the transaction
  ///
  /// In en, this message translates to:
  /// **'Restart transaction'**
  String get restartTransaction;

  /// Button label to request the required Bluetooth or location permissions
  ///
  /// In en, this message translates to:
  /// **'Grant permissions'**
  String get grantPermissions;

  /// Button label to open the system settings to turn on NFC
  ///
  /// In en, this message translates to:
  /// **'Enable NFC'**
  String get enableNfc;

  /// Button label to open the system settings to turn on Bluetooth
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth'**
  String get enableBluetooth;

  /// Button label to start a transaction
  ///
  /// In en, this message translates to:
  /// **'Start transaction'**
  String get startTransaction;

  /// Message shown when the device has no NFC hardware
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device.'**
  String get nfcNotAvailable;

  /// Message shown when the device has no Bluetooth hardware
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is not available on this device.'**
  String get bluetoothNotAvailable;

  /// Label of the navigation bar destination for the contacts list
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// Label of the navigation bar destination for starting a run
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get navStartRun;

  /// Label of the navigation bar destination for the user's identities
  ///
  /// In en, this message translates to:
  /// **'Identities'**
  String get navIdentities;

  /// Title of the Android biometric prompt used to unlock the personal vault
  ///
  /// In en, this message translates to:
  /// **'Unlock vault'**
  String get vaultUnlockTitle;

  /// Subtitle of the Android biometric prompt explaining why the vault must be unlocked
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to unlock your personal vault and start using PGPtouch.'**
  String get vaultUnlockSubtitle;

  /// Negative button label of the biometric prompt that cancels unlocking the vault
  ///
  /// In en, this message translates to:
  /// **'Keep locked'**
  String get vaultUnlockKeepLocked;

  /// Title of the message shown when unlocking the vault failed because the Android Keystore reports the key as locked until the device is locked and unlocked again
  ///
  /// In en, this message translates to:
  /// **'Device reauthentication required'**
  String get vaultUnlockDeviceReauthRequiredTitle;

  /// Message shown when unlocking the vault failed because the Android Keystore reports the key as locked until the device is locked and unlocked again
  ///
  /// In en, this message translates to:
  /// **'Android couldn’t access the vault’s secure key. This may happen if the device needs to be reauthenticated.'**
  String get vaultUnlockDeviceReauthRequiredMessage;

  /// First step instruction for reauthenticating the device when the vault's secure key is inaccessible
  ///
  /// In en, this message translates to:
  /// **'Lock your phone'**
  String get vaultUnlockDeviceReauthRequiredStep1;

  /// Second step instruction for reauthenticating the device when the vault's secure key is inaccessible
  ///
  /// In en, this message translates to:
  /// **'Unlock your phone'**
  String get vaultUnlockDeviceReauthRequiredStep2;

  /// Third step instruction for reauthenticating the device when the vault's secure key is inaccessible
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get vaultUnlockDeviceReauthRequiredStep3;

  /// Option in the add contact source chooser to search for a contact online
  ///
  /// In en, this message translates to:
  /// **'Search online'**
  String get addContactSourceSearch;

  /// Option in the add contact source chooser to import a contact from the clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get addContactSourceClipboard;

  /// Option in the add contact source chooser to import a contact from a file
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get addContactSourceFile;

  /// Option in the add identity source chooser to create a new identity (key pair) from scratch
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get addIdentitySourceCreate;

  /// Error shown when the entered passphrase could not unlock the private key
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase.'**
  String get passphraseInputWrong;

  /// Text above the passphrase field explaining that a passphrase is required for the listed identities
  ///
  /// In en, this message translates to:
  /// **'You need to enter a passphrase for the following identities:'**
  String get passphraseInputPrompt;

  /// Encloses the given text in typographic quotation marks
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String enquote(String text);

  /// Label of the passphrase text field
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseInputLabel;

  /// Title of the checkbox that stores the passphrase in the vault
  ///
  /// In en, this message translates to:
  /// **'Remember using Vault'**
  String get passphraseInputRemember;

  /// Description of the checkbox that stores the passphrase in the vault
  ///
  /// In en, this message translates to:
  /// **'This will store the passphrase on your device so you don’t have to enter it again.'**
  String get passphraseInputRememberDescription;

  /// Button label to skip entering the passphrase
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get passphraseInputSkip;

  /// Button label to submit the entered passphrase
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get passphraseInputContinue;

  /// Text above the backup code fields explaining that a 24 character backup code is required to open the selected backup file
  ///
  /// In en, this message translates to:
  /// **'The selected file is a Backup File, so you need the designated 24 character backup code to proceed.'**
  String get backupCodeInputPrompt;

  /// Error shown when the entered backup code cannot decrypt the backup
  ///
  /// In en, this message translates to:
  /// **'Wrong backup code.'**
  String get backupCodeInputWrong;

  /// Text above the generated backup code explaining that it is needed to use the Backup File later on and must be stored separately from it
  ///
  /// In en, this message translates to:
  /// **'The following 24 character backup code is needed to use the Backup File later on. Store it securely in a separate location away from the Backup File.'**
  String get backupCodeShowPrompt;

  /// Button label to copy the generated backup code to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get backupCodeShowCopy;

  /// Message shown when the clipboard contains no text while adding a contact
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty.'**
  String get addContactClipboardEmpty;

  /// Message shown when the clipboard content does not contain any readable public keys
  ///
  /// In en, this message translates to:
  /// **'Failed to read clipboard content.'**
  String get addContactClipboardReadFailed;

  /// Message shown after public keys were successfully read from the clipboard
  ///
  /// In en, this message translates to:
  /// **'Read {count, plural, one{{count} key} other{{count} keys}} from clipboard.'**
  String addContactClipboardReadKeys(int count);

  /// Message shown when the selected file could not be read
  ///
  /// In en, this message translates to:
  /// **'Failed to read file.'**
  String get addContactFileFailed;

  /// Message shown when the selected file does not contain any readable public keys
  ///
  /// In en, this message translates to:
  /// **'Failed to read file content.'**
  String get addContactFileReadFailed;

  /// Message shown after public keys were successfully read from a file
  ///
  /// In en, this message translates to:
  /// **'Read {count, plural, one{{count} key} other{{count} keys}} from file.'**
  String addContactFileReadKeys(int count);

  /// Label of the text field used to search for a contact's public key online
  ///
  /// In en, this message translates to:
  /// **'Email Address / Identity'**
  String get addContactSearchLabel;

  /// Example email address shown as hint in the online key search text field
  ///
  /// In en, this message translates to:
  /// **'user@example.net'**
  String get addContactSearchHint;

  /// Helper text below the online key search text field explaining what to enter
  ///
  /// In en, this message translates to:
  /// **'This usually is equal to the person’s primary email address.'**
  String get addContactSearchHelper;

  /// Error shown in the search text field when the entered query is shorter than 3 characters
  ///
  /// In en, this message translates to:
  /// **'Query must be at least 3 characters long.'**
  String get addContactSearchQueryTooShort;

  /// Error shown in the search text field when the entered query is not an email address
  ///
  /// In en, this message translates to:
  /// **'Query must be a valid email address.'**
  String get addContactSearchQueryInvalidEmail;

  /// Error shown in the search text field when no public keys were found for the entered email address
  ///
  /// In en, this message translates to:
  /// **'No keys found for the given email address.'**
  String get addContactSearchNoKeys;

  /// Error shown in the search text field when fetching public keys failed, for example due to a network error
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch keys.'**
  String get addContactSearchFailed;

  /// Subtitle of a search result whose key data could not be parsed, is invalid, or cannot be used
  ///
  /// In en, this message translates to:
  /// **'Key cannot be used here.'**
  String get addContactSearchResultUnusable;

  /// Reason appended to the unusable search result subtitle when the key has expired
  ///
  /// In en, this message translates to:
  /// **'It has already expired.'**
  String get addContactSearchResultExpired;

  /// Reason appended to the unusable search result subtitle when the key has been revoked
  ///
  /// In en, this message translates to:
  /// **'It has been revoked.'**
  String get addContactSearchResultRevoked;

  /// Reason appended to the unusable search result subtitle when the key could not be parsed or is otherwise invalid
  ///
  /// In en, this message translates to:
  /// **'This app is having trouble reading it.'**
  String get addContactSearchResultUnreadable;

  /// Tooltip of the warning icon on a search result whose key was not found in the primary (first) search result
  ///
  /// In en, this message translates to:
  /// **'This key is not present in the primary search result.'**
  String get addContactSearchResultNotInPrimaryTooltip;

  /// Tooltip of the warning icon on a search result whose key differs from the same key in the primary (first) search result
  ///
  /// In en, this message translates to:
  /// **'This key is different from its counterpart in the primary search result. It may be outdated.'**
  String get addContactSearchResultDiffersTooltip;

  /// Tooltip of the star icon on the preferred search result
  ///
  /// In en, this message translates to:
  /// **'This is the preferred search result. You should probably pick this key before any others.'**
  String get addContactSearchResultPreferredTooltip;

  /// Tooltip of the check icon on a search result whose key server verifies the identity of uploaded keys
  ///
  /// In en, this message translates to:
  /// **'This key server verifies that uploaded keys belong to their listed email addresses.'**
  String get addContactSearchResultIdentityVerifiedTooltip;

  /// Message shown after a public key from the online search was selected and added
  ///
  /// In en, this message translates to:
  /// **'Added 1 key from search.'**
  String get addContactSearchAdded;

  /// Name of the key source for the advanced Web Key Directory (WKD) lookup method
  ///
  /// In en, this message translates to:
  /// **'Web Key Directory (Advanced)'**
  String get keyFetchOriginWebKeyDirectoryAdvanced;

  /// Name of the key source for the direct Web Key Directory (WKD) lookup method
  ///
  /// In en, this message translates to:
  /// **'Web Key Directory (Direct)'**
  String get keyFetchOriginWebKeyDirectoryDirect;

  /// Generic name of a key source that is an HKP keyserver
  ///
  /// In en, this message translates to:
  /// **'HKP Key Server'**
  String get keyFetchOriginHkpKeyServer;

  /// Title of a search result that was fetched from a named keyserver
  ///
  /// In en, this message translates to:
  /// **'{name} Keyserver'**
  String keyFetchKeyserverTitle(String name);

  /// Message shown when the contact list is empty
  ///
  /// In en, this message translates to:
  /// **'No contacts yet.'**
  String get contactsEmpty;

  /// Tooltip of the floating action button used to add a new contact
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get contactsAddTooltip;

  /// Call to action shown under the locked vault icon; tapping it starts unlocking the vault
  ///
  /// In en, this message translates to:
  /// **'Unlock!'**
  String get identitiesUnlock;

  /// Message shown when the identities list is empty, with a hint to create one
  ///
  /// In en, this message translates to:
  /// **'No identities yet.\nStart by creating one!'**
  String get identitiesEmpty;

  /// Headline of the section listing the properties of an identity key
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get identityDetailsHeadline;

  /// Title of the entry showing when the key was created
  ///
  /// In en, this message translates to:
  /// **'Creation'**
  String get identityCreation;

  /// Title of the entry showing when the key expires
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get identityExpiration;

  /// Value shown as expiration date when the key does not expire
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get identityExpirationNever;

  /// Warning shown on an identity whose key has expired
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get identityExpired;

  /// Warning shown on an identity whose key has been revoked
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get identityRevoked;

  /// Revocation reason shown when the key was revoked without giving a reason
  ///
  /// In en, this message translates to:
  /// **'No reason given'**
  String get identityRevocationReasonNoReason;

  /// Revocation reason shown when the key was replaced by a newer key
  ///
  /// In en, this message translates to:
  /// **'Key superseded'**
  String get identityRevocationReasonKeySuperseded;

  /// Revocation reason shown when the secret key may have been exposed
  ///
  /// In en, this message translates to:
  /// **'Key compromised'**
  String get identityRevocationReasonKeyCompromised;

  /// Revocation reason shown when the key is no longer in use
  ///
  /// In en, this message translates to:
  /// **'Has been retired'**
  String get identityRevocationReasonKeyRetired;

  /// Revocation reason shown when the user ID of the key is no longer valid
  ///
  /// In en, this message translates to:
  /// **'Invalid user ID'**
  String get identityRevocationReasonUserIdInvalid;

  /// Title of the entry showing the strength of the key
  ///
  /// In en, this message translates to:
  /// **'Key strength'**
  String get identityKeyStrength;

  /// Title of the entry showing the OpenPGP version of the key
  ///
  /// In en, this message translates to:
  /// **'Key version'**
  String get identityKeyVersion;

  /// Title of the entry showing the key ID
  ///
  /// In en, this message translates to:
  /// **'Key ID'**
  String get identityKeyId;

  /// Title of the entry showing the key fingerprint
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get identityFingerprint;

  /// Status shown when the passphrase of the key is stored on the device
  ///
  /// In en, this message translates to:
  /// **'Passphrase is stored'**
  String get identityPassphraseStored;

  /// Status shown when the passphrase of the key is not stored on the device
  ///
  /// In en, this message translates to:
  /// **'Passphrase is not stored'**
  String get identityPassphraseNotStored;

  /// Placeholder shown when a value (e.g. name, date, key detail) is not available
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get valueMissing;

  /// Optional comment of an identity, shown in parentheses next to its name
  ///
  /// In en, this message translates to:
  /// **'({comment})'**
  String identityComment(String comment);

  /// Short badge shown on an identity tile when its passphrase is stored on the device
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get identityPassphraseRemembered;

  /// Headline of the section listing the actions available for an identity key
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get identityActionsHeadline;

  /// Title of the action that exports the key to a file
  ///
  /// In en, this message translates to:
  /// **'Export key'**
  String get identityExportKey;

  /// Title of the action that exports the key as an encrypted backup file protected by a backup code
  ///
  /// In en, this message translates to:
  /// **'Export as backup'**
  String get identityExportBackup;

  /// Title of the action that deletes the key and its stored passphrase
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get identityDeleteKey;

  /// Title of the action that deletes only the stored passphrase of the key
  ///
  /// In en, this message translates to:
  /// **'Delete stored passphrase'**
  String get identityDeleteStoredPassphrase;

  /// Snackbar message shown after the key backup was saved successfully
  ///
  /// In en, this message translates to:
  /// **'Backup exported.'**
  String get identityBackupExported;

  /// Snackbar message shown when exporting the key backup failed
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup.'**
  String get identityBackupExportFailed;

  /// Snackbar message shown after the key was exported successfully
  ///
  /// In en, this message translates to:
  /// **'Key exported.'**
  String get identityKeyExported;

  /// Snackbar message shown when exporting the key failed
  ///
  /// In en, this message translates to:
  /// **'Failed to export key.'**
  String get identityKeyExportFailed;

  /// Snackbar message shown after the key was deleted successfully
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get identityDeleted;

  /// Snackbar message shown when deleting the key failed
  ///
  /// In en, this message translates to:
  /// **'Failed to delete.'**
  String get identityDeleteFailed;

  /// Snackbar message shown after the stored passphrase of the key was removed successfully
  ///
  /// In en, this message translates to:
  /// **'Stored passphrase removed.'**
  String get identityStoredPassphraseRemoved;

  /// Snackbar message shown when removing the stored passphrase of the key failed
  ///
  /// In en, this message translates to:
  /// **'Failed to remove stored passphrase.'**
  String get identityStoredPassphraseRemoveFailed;

  /// Title of the action that fetches the latest version of the public key from online sources
  ///
  /// In en, this message translates to:
  /// **'Update public key'**
  String get identityUpdatePublicKey;

  /// Title of the action that fetches the latest version of a contact's key from online sources
  ///
  /// In en, this message translates to:
  /// **'Update key'**
  String get identityUpdateKey;

  /// Snackbar message shown after the public key was updated successfully
  ///
  /// In en, this message translates to:
  /// **'Updated successfully from: {origin}'**
  String identityPublicKeyUpdated(String origin);

  /// Snackbar message shown when no online source offers an updated public key
  ///
  /// In en, this message translates to:
  /// **'No source available.'**
  String get identityPublicKeyUpdateNoSource;

  /// Snackbar message shown when updating the public key failed
  ///
  /// In en, this message translates to:
  /// **'Failed to update.'**
  String get identityPublicKeyUpdateFailed;

  /// Title of the setting that selects which HKP key servers are used to search for public keys
  ///
  /// In en, this message translates to:
  /// **'HKP key servers'**
  String get settingsHkpKeyServers;

  /// Headline of the settings section containing assorted options
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get settingsMiscellaneous;

  /// Title of the option that deletes all passphrases the app has stored
  ///
  /// In en, this message translates to:
  /// **'Delete stored passphrases'**
  String get settingsDeleteStoredPassphrases;

  /// Title of the option that opens the about screen
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get settingsAboutApp;

  /// Tooltip of the app bar button that unlocks the vault while it is locked
  ///
  /// In en, this message translates to:
  /// **'Unlock vault'**
  String get appBarUnlockTooltip;

  /// Tooltip of the app bar button while the vault is already unlocked
  ///
  /// In en, this message translates to:
  /// **'Vault unlocked'**
  String get appBarUnlockedTooltip;

  /// Tooltip of the app bar button that opens the settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appBarSettingsTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
