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

  /// Button label to generate a new PGP key pair
  ///
  /// In en, this message translates to:
  /// **'Generate keys'**
  String get generateKeys;

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

  /// Title of the warning shown when Android's Tap to share could not be blocked
  ///
  /// In en, this message translates to:
  /// **'Tap to share is interfering'**
  String get tapToShareInterferingTitle;

  /// Explanation and instructions for the warning shown when Android's Tap to share could not be blocked
  ///
  /// In en, this message translates to:
  /// **'Android\'s Tap to share could not be blocked. Turn it off in Settings > Google > Quick Share > Tap to share, or taps may open the contact-share popup.'**
  String get tapToShareInterferingMessage;

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
