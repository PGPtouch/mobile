# PGPtouch (mobile)

Privacy policy - Last updated: 12 November 2026

This policy explains which personal data the Android app “PGPtouch” (package `com.jhubi1.apps.pgptouch`, source code at <https://github.com/PGPtouch/mobile>) processes, why, and which rights you have under the General Data Protection Regulation (GDPR).

### Scope

This policy only applies to official first-party builds of the app, published by the controller and correctly signed with the controller’s signing key. For modified, re-signed or third-party builds, this policy does not apply. Such builds may behave differently, and the controller has no influence on or responsibility for them.

### In short

Your keys, contacts and settings stay on your device. The app has no user accounts and does not show ads. Anonymous usage statistics are only sent if you give your consent. All servers the app talks to by itself (feature flags and statistics) are operated by the controller and not by a third party.

## 1. Controller

JHubi1 (developer of PGPtouch)
Email: [me@jhubi1.com](mailto:me@jhubi1.com)

There is no data protection officer; please use the address above for all privacy matters.

## 2. Overview

| Processing                        | Data                                            | Leaves your device?                     | Legal basis                             |
| --------------------------------- | ----------------------------------------------- | --------------------------------------- | --------------------------------------- |
| Local key and contact storage     | Keys, User IDs, passphrases, settings           | No                                      | Not processed by the controller (see 3) |
| Key exchange by NFC and Bluetooth | Public keys, User IDs, cryptographic signatures | Only directly to the other device       | Your instruction, Art. 6(1)(b)          |
| Key search and key update         | Email address, key fingerprint, IP address      | Yes, to key servers and email providers | Your instruction, Art. 6(1)(b)          |
| Anonymous usage statistics        | Event data, device model, OS version, language  | Yes, only with your consent             | Consent, Art. 6(1)(a)                   |
| Feature flags                     | Random flag number, beta setting, IP address    | Yes                                     | Legitimate interest, Art. 6(1)(f)       |

## 3. Data stored only on your device

The following data is created and stored locally. The controller has no access to it and receives no copy, so he does not process it. It is deleted when you remove the data in the app or uninstall the app.

### Identities (your own keys)

OpenPGP public and private keys, their fingerprints, creation and expiry dates, revocation state, and the names, comments and email addresses in their User IDs. They are stored in an encrypted database (SQLite3 Multiple Ciphers, SQLCipher-compatible). The database key is a random value kept in the Android Keystore through secure storage and protected by strong biometric authentication (fingerprint or face, as provided by your device). The app asks for this authentication to unlock your keys. If the private key itself is protected by a passphrase, it stays protected by that passphrase.

### Remembered passphrases

If you choose to remember the passphrase of a key, it is stored in the same biometric-protected secure storage. You can delete it again at any time.

### Contacts

Public keys of other people with their User IDs (names, comments, email addresses), fingerprints and dates. This database is stored on your device without a separate app-level encryption, as it only holds public information. The file-based encryption of the Android device storage applies.

### Settings

The identity you selected for exchanges (database ID, display name and expiry), your key server selection, the beta setting, your decision on usage statistics and a random flag number (see 7). They are stored in the app’s preferences.

### Exports and backups

When you export keys or create an encrypted backup, the app writes a file to the location you choose with the system file picker. The backup is encrypted with a backup code shown to you. Exported plain private keys are not protected by the app, so store them securely. The app does not upload exports anywhere.

### Clipboard and files

The app reads the clipboard or a file only when you choose “Paste from clipboard” or “From file” while importing keys. Copying (for example an email address or a fingerprint) writes to the clipboard only on your action.

Because this data is yours and is not transmitted to the controller, he cannot access, correct or delete it for you. You can do so yourself in the app or by clearing the app data.

## 4. Permissions and device features

| Permission / feature                                         | Purpose                                                                                                                                                                               |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bluetooth scan, connect and advertise (Android 12 and later) | Finding and communicating with the other device during an exchange. The scan permission is declared “never for location”.                                                             |
| Location (Android 11 and lower only)                         | Required by Android for Bluetooth Low Energy scanning on these versions. The app does not read or use your location.                                                                  |
| NFC                                                          | Detecting the other device and starting an exchange. The app also reads the NFC antenna position and related system NFC settings to guide you where to tap. This stays on the device. |
| Biometric                                                    | Unlocking the key store (see 3). The app does not receive your biometric data; the Android system performs the check.                                                                 |
| Internet                                                     | Key search and update (see 6), feature flags (see 7) and, if you consented, statistics (see 8).                                                                                       |
| Vibration                                                    | Haptic feedback during an exchange.                                                                                                                                                   |

You can revoke the runtime permissions in the Android system settings. The key exchange then no longer works.

## 5. Key exchange between two devices

During an exchange, your device and the other device talk directly over NFC and Bluetooth Low Energy. Your device sends your selected public key and its User IDs and signs data with your private key; it receives the same from the other device. No server is involved and the controller does not see the exchange. After a successful exchange, the app shows you the User IDs and fingerprint of the received key; it does not save them as a contact by itself.

The other person receives the public data you selected for the exchange (name, email address and other User ID parts of your public key, fingerprint). Choose the identity you share deliberately. Nearby Bluetooth devices may see that a Bluetooth signal is being sent during the exchange.

## 6. Key search and key update (key servers)

If you search for a contact’s key or update an existing key, the app contacts key sources on your request, over HTTPS only:

- Web Key Directory (WKD) of the domain in the email address. The server of that domain receives the email address.
- HKP key servers that you select in Settings. They receive the email address you searched for. When you update a key, they may also receive the fingerprint of that key. The default servers are `keys.openpgp.org`, `keys.mailvelope.com` and `keyserver.ubuntu.com`. You can additionally choose `api.protonmail.ch`, `pgp.mit.edu`, `pgp.surfnet.nl`, `pgp.circl.lu`, `pgpkeys.eu` and `keyserver.dobrev.eu`.

These servers also receive your IP address and technical connection data. They are operated by third parties who are independent controllers; the controller of this app does not receive the requests or the responses. Please see the privacy policies of the respective operators. Some operators may be located outside the European Economic Area; the transfer takes place only to carry out your request (Art. 49(1)(b) GDPR). Public keys found this way are shown to you and are only saved if you add them.

## 7. Feature flags

At startup, the app asks a feature-flag service which features are enabled for your installation (for example beta features or staged rollouts). The service is operated by the controller and not by a third party. For this, the app sends:

- a randomly generated 32-character flag number created on first use (not derived from your device, account or keys),
- your “Beta features” setting,
- your IP address and technical connection data (inevitable for any internet request).

The flag number is stored in the app’s preferences and remains until you clear the app data or uninstall the app. It is a pseudonymous identifier and therefore personal data. This request is made independently of your decision on statistics in section 8. You can see your flag number in Settings → Privacy → Feature rollout.

### Purpose and legal basis

Controlled rollout of features and error containment. The legal basis is the legitimate interest of the controller, Art. 6(1)(f) GDPR. You can object at any time (see 10).

### Hosting and retention

The server runs at Hetzner Online GmbH in Nuremberg, Germany. Hetzner provides the hardware as a processor on behalf of the controller; the data is not transferred outside the European Union. Data of your requests (for example flag number, requested feature, result and connection data) may be contained in log files of the server. They are deleted together with these log files, when these are rotated or deleted.

## 8. Anonymous usage statistics

In end-user release versions of the app, no usage statistics are sent unless you consent. You can give or decline your consent when the app asks for it and at any time in Settings → Privacy (“Enable tracking”). Declining is as easy as consenting, and the app works the same either way. As long as you have not consented, no events are sent. You can withdraw your consent at any time with the same switch; from then on, no further events are sent. Your decision is stored only on your device.

### Purpose and legal basis

Understanding how reliable and fast the app works (for example, how often exchanges succeed and where they fail) in order to improve it. The legal basis is your consent, Art. 6(1)(a) GDPR and § 25(1) TDDDG. Withdrawal does not affect the lawfulness of earlier processing.

### Hosting and retention

Events are sent over HTTPS to an analytics server. It is operated by the controller and not by a third party. The server runs at Hetzner Online GmbH in Nuremberg, Germany; Hetzner provides the hardware as a processor on behalf of the controller, and the data is not transferred outside the European Union. Events are kept for 5 years and are then deleted automatically.

### Data sent with every event

Event time, app version, operating system name and version, system language and region, whether the app is a debug version, and a random session ID that is renewed after one hour of inactivity. It is not linked to the flag number from section 7, to device identifiers or to your keys.

When an event is received, the server additionally derives your approximate location (country, region and city) from the IP address and creates a pseudonymous daily user hash from IP address, browser identification and a salt that is replaced every 24 hours. The IP address itself is not stored. Once the salt is deleted, the hash can neither be reversed nor linked to your events on other days.

### Data sent with specific events

Only coarse outcomes, categories, counts and durations are sent:

| Event                                | Content                                                                                                                                                                                                                           |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `initialized`                        | App start                                                                                                                                                                                                                         |
| `exchangeAttempt`                    | Outcome and reason, role in the exchange (sender or receiver), reached stage, durations of the steps, retry count, how often the app went to background, whether the NFC antenna position is known, device manufacturer and model |
| `keyStoreUnlock`                     | Outcome, trigger, duration, technical error code on failure                                                                                                                                                                       |
| `passphrasePrompt`                   | Outcome, number of attempts, whether a stored passphrase failed or was remembered, durations                                                                                                                                      |
| `identityCreated`                    | Algorithm, RSA key size, number of User IDs, whether it expires, whether it can encrypt, generation time                                                                                                                          |
| `addIdentityFlow` / `addContactFlow` | Outcome, counts of added keys and duplicates, counts of stored passphrases, duration                                                                                                                                              |
| `importSource`                       | Import source (clipboard, file, …) and outcome. No key data and no file contents are transmitted.                                                                                                                                 |
| `contactSearch`                      | Outcome, number of results, number of valid keys, duration, number of servers used                                                                                                                                                |
| `keyExport`                          | Whether an identity or contact, format (plain or backup), outcome                                                                                                                                                                 |
| `keyUpdate` / `keyDeleted`           | Whether an identity or contact, outcome                                                                                                                                                                                           |

### Data never sent

Key material, fingerprints, User IDs, names, email addresses, search terms, file names, passphrases, contact lists or raw error messages.

### Identifiability

Because the events contain no persistent identifier and the daily salt is not kept, they generally cannot be assigned to you. For this reason, requests for access, correction or erasure of such events usually cannot be fulfilled (Art. 11 GDPR).

## 9. Other connections and third parties

### Privacy policy page

If you tap “Privacy policy” in Settings, the in-app browser opens the policy page at `privacy.jhubi1.com` together with your app language. The web server receives your IP address and the usual browser data.

### Inquiry page

If you tap “Open inquiry” in Settings → Privacy → Feature rollout, the in-app browser opens the inquiry form at `privacy.jhubi1.com` together with your flag number, so that your data can be found. The web server receives your IP address, the usual browser data and the flag number.

The form is provided by Tally (Tally BV, Belgium), which processes the form data on behalf of the controller as a processor under a data processing agreement. The data is stored in Europe; Tally may use further service providers, see Tally’s privacy notice. Tally receives your IP address, the usual browser data and everything you enter in the form (for example your email address, your flag number and the content of your request). This data is processed to handle your request (Art. 6(1)(c) GDPR).

The data is kept until your request is resolved and is deleted afterwards. If the controller asks you questions and you do not reply, the request is considered resolved without result or action taken after two weeks. Only one request per email address can be open through the form at a time. If you need to make further requests, please write an email instead.

### Email links

Tapping an email address of a key opens your email app. What happens then is governed by that app.

### Open-source licenses and project page

The “About” screen lists licenses from the app itself. The link to GitHub opens in your browser, where GitHub’s privacy policy applies.

### No advertising or further collection

The app has no advertising, no social media plugins and does not include any ad or marketing software. It does not collect your location, contacts from your address book, photos, camera or microphone data.

## 10. Your rights

Under the GDPR you have the right to:

- access (Art. 15), rectification (Art. 16), erasure (Art. 17), restriction (Art. 18) and data portability (Art. 20) concerning your personal data,
- object at any time to processing based on legitimate interest (Art. 21), for reasons arising from your particular situation,
- withdraw consent at any time with effect for the future (Art. 7(3)), here by switching off “Enable tracking” in Settings → Privacy,
- lodge a complaint with a supervisory authority (Art. 77), especially in the EU member state of your habitual residence, place of work or the place of the alleged infringement.

To request data insight or deletion, tap “Open inquiry” in Settings → Privacy → Feature rollout, use the inquiry form at <https://privacy.jhubi1.com/claim>, or write to [me@jhubi1.com](mailto:me@jhubi1.com). The controller can only find data about you if it can be assigned to you, for example through your flag number (see 7). Most data is only on your device and can be deleted by you directly (see 3). Through the form, only one request per email address can be open at a time; for further requests, please write an email to the address above. To reset the flag number, clear the app data or reinstall the app.

## 11. Provision of data, automated decisions

You are not obliged to provide personal data. The app works without consenting to statistics. No automated decision-making or profiling within the meaning of Art. 22 GDPR takes place.

## 12. Security

The key database is encrypted and its key is protected by the Android Keystore with biometric authentication, all network requests use HTTPS, and the app does not request more permissions than needed. Rooting or otherwise modifying your device is discouraged, as it weakens the protection of the Android Keystore and the isolation of the app. No system is absolutely secure; keep your device and operating system up to date and protect private keys with a strong passphrase.

## 13. Changes

This policy may be updated when the app or the legal situation changes. The current version is available at <https://privacy.jhubi1.com/?app=4c2c4490f6164d4db7f399d1c87c18f9>. The date at the top shows when it was last changed.
