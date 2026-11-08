import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:dart_pg/dart_pg.dart' show OpenPGP, PacketList, PrivateKey;
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_helper/material_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/shared.dart';

import '../components/passphrase_input.dart';
import '../components/research_point.dart';
import '../l10n/app_localizations.dart';

part 'key_store.g.dart';

@TableIndex(name: "keys_fingerprint", columns: {#fingerprint})
class Keys extends Table {
  IntColumn get id => integer().autoIncrement()();

  BlobColumn get fingerprint => blob()();
  BlobColumn get publicData => blob().unique()();
  BlobColumn get privateData => blob().unique()();

  BoolColumn get isRevoked => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

extension KeyExtension on Key {
  List<KeyUserIdsCompanion> generateInsertsForUserIds(List<String> userIds) {
    if (userIds.isEmpty) return const [];
    final parsed = userIds.map(UserId.parse);
    return parsed
        .map(
          (u) => KeyUserIdsCompanion.insert(
            parent: id,
            name: .absentIfNull(u.name),
            comment: .absentIfNull(u.comment),
            email: u.email,
          ),
        )
        .toList();
  }

  Future<List<KeyUserId>> getUserIds(KeyStore db) =>
      (db.select(db.keyUserIds)..where((u) => u.parent.equals(id))).get();
}

class KeyUserIds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parent =>
      integer().references(Keys, #id, onUpdate: .cascade, onDelete: .cascade)();

  TextColumn get name => text().nullable()();
  TextColumn get comment => text().nullable()();
  TextColumn get email => text()();
}

@DriftDatabase(tables: [Keys, KeyUserIds])
class KeyStore extends _$KeyStore {
  KeyStore(String passphrase, [QueryExecutor? executor])
    : assert(passphrase.isNotEmpty, "Passphrase must not be empty"),
      super(executor ?? _openConnection(passphrase: passphrase));

  @override
  int get schemaVersion => 1;

  static const _databaseName = "keyStore";

  /// Removes the database files. Without the nonce the database can't be
  /// decrypted anymore, so it is only useful to clear it before creating a new one.
  static Future<void> deleteDatabaseFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    for (final suffix in const ["", "-wal", "-shm", "-journal"]) {
      final file = File("${directory.path}/$_databaseName.sqlite$suffix");
      if (await file.exists()) await file.delete();
    }
  }

  static QueryExecutor _openConnection({required String passphrase}) =>
      driftDatabase(
        name: _databaseName,
        native: DriftNativeOptions(
          databaseDirectory: getApplicationDocumentsDirectory,
          setup: (rawDb) {
            if (rawDb.select("PRAGMA cipher").isEmpty) {
              throw StateError("Database is not encryptable");
            }
            rawDb.execute("PRAGMA key = '${passphrase.replaceAll("'", "''")}'");
            try {
              rawDb.execute("SELECT count(*) FROM sqlite_master");
            } catch (e) {
              throw StateError("Failed to verify database encryption: $e");
            }
            rawDb.execute("VACUUM");
          },
        ),
      );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: _schemaUpgrade,
    beforeOpen: (details) async =>
        await customStatement("PRAGMA foreign_keys = ON"),
  );

  Future<void> insertKey(KeysCompanion key, List<String> userIds) =>
      transaction(() async {
        final id = await into(keys).insert(key);
        final insertedKey = await (select(
          keys,
        )..where((k) => k.id.equals(id))).getSingleOrNull();
        if (insertedKey == null) throw Exception("Failed to insert key");
        for (final insert in insertedKey.generateInsertsForUserIds(userIds)) {
          await into(keyUserIds).insert(insert);
        }
      });

  Future<void> updateKey(KeysCompanion key, List<String> userIds) =>
      transaction(() async {
        final existing =
            await (select(keys)
                  ..where((k) => k.fingerprint.equals(key.fingerprint.value)))
                .getSingleOrNull();
        if (existing == null) {
          throw Exception("Failed to update key: key not found");
        }
        final id = existing.id;
        if (key.id.present && key.id.value != id) {
          throw ArgumentError("updateKey must not change the id of a key");
        }
        await update(keys).replace(key.copyWith(id: Value(id)));
        final insertedKey = await (select(
          keys,
        )..where((k) => k.id.equals(id))).getSingleOrNull();
        if (insertedKey == null) throw Exception("Failed to update key");
        await (delete(keyUserIds)..where((k) => k.parent.equals(id))).go();
        for (final insert in insertedKey.generateInsertsForUserIds(userIds)) {
          await into(keyUserIds).insert(insert);
        }
      });
}

extension Migrations on GeneratedDatabase {
  OnUpgrade get _schemaUpgrade {
    // return stepByStep(from1To2: (m, schema) async {});
    return (_, _, _) => Future.syncValue(null);
  }
}

enum UnlockResult { unlocked, deviceReauthRequired, failed }

bool _isAlgorithmChange(Object error) =>
    error is PlatformException &&
    (error.message?.contains("Algorithm changed detected") ?? false);

@visibleForTesting
bool isDeviceReauthRequired(Object error) =>
    error is PlatformException &&
    "${error.message}${error.details}".contains(
      "UserNotAuthenticatedException",
    );

final class KeyStoreHandler extends ChangeNotifier {
  KeyStoreHandler._();
  static final _instance = KeyStoreHandler._();
  static KeyStoreHandler get instance => _instance;

  bool _isLocked = true;
  bool get isLocked => _isLocked;

  KeyStore? _keyStore;
  KeyStore? get keyStore => isLocked ? null : _keyStore;

  FlutterSecureStorage? _flutterSecureStorage;
  FlutterSecureStorage _storage(AppLocalizations appLocalizations) =>
      _flutterSecureStorage ??= FlutterSecureStorage(
        aOptions: AndroidOptions.biometric(
          resetOnError: false,
          migrateOnAlgorithmChange: false,
          enforceBiometrics: true,
          biometricType: .strongBiometricOnly,
          requireBiometricConfirmation: false,
          biometricPromptTitle: appLocalizations.vaultUnlockTitle,
          biometricPromptSubtitle: appLocalizations.vaultUnlockSubtitle,
          biometricPromptNegativeButton: appLocalizations.vaultUnlockKeepLocked,
        ),
      );

  String _bytesToHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, "0"))
      .join()
      .toLowerCase();

  Future<UnlockResult> unlock(
    AppLocalizations appLocalizations, {
    String trigger = "manual",
  }) async {
    final old = _isLocked;
    final stopwatch = Stopwatch()..start();
    try {
      try {
        await _unlockOnce(appLocalizations);
      } catch (e) {
        if (!_isAlgorithmChange(e)) rethrow;
        await _unlockOnce(appLocalizations);
      }
      _isLocked = false;
      if (old && !_isLocked) {
        ResearchPoint.trackEvent("keyStoreUnlock", {
          "outcome": "unlocked",
          "trigger": trigger,
          "durationMs": stopwatch.elapsedMilliseconds,
        });
      }
      return UnlockResult.unlocked;
    } catch (e, s) {
      debugPrint("Failed to unlock key store: $e\n$s");
      _keyStore = null;
      _isLocked = true;
      final deviceReauthRequired = isDeviceReauthRequired(e);
      ResearchPoint.trackEvent("keyStoreUnlock", {
        "outcome": deviceReauthRequired ? "reauthRequired" : "failed",
        "trigger": trigger,
        "errorCode": e is PlatformException ? e.code : e.runtimeType.toString(),
        "durationMs": stopwatch.elapsedMilliseconds,
      });
      return deviceReauthRequired
          ? UnlockResult.deviceReauthRequired
          : UnlockResult.failed;
    } finally {
      if (old != _isLocked) notifyListeners();
    }
  }

  Future<void> _unlockOnce(AppLocalizations appLocalizations) async {
    var nonce = await _storage(appLocalizations).read(key: "nonce");
    if (nonce == null) {
      await _keyStore?.close();
      _keyStore = null;
      await KeyStore.deleteDatabaseFiles();
      nonce = _bytesToHex(math.Random.secure().nextByte(32));
      await _storage(appLocalizations).write(key: "nonce", value: nonce);
    }
    _keyStore ??= KeyStore(nonce);
  }

  Future<String?> getKeyPassphrase(Uint8List fingerprint) async {
    if (_keyStore == null) throw StateError("KeyStore is locked");
    return await _flutterSecureStorage!.read(
      key: "key_${_bytesToHex(fingerprint)}",
    );
  }

  Future<bool> hasKeyPassphrase(Uint8List fingerprint) async {
    if (_keyStore == null) throw StateError("KeyStore is locked");
    return await _flutterSecureStorage!.containsKey(
      key: "key_${_bytesToHex(fingerprint)}",
    );
  }

  Future<void> setKeyPassphrase(
    Uint8List fingerprint,
    String passphrase,
  ) async {
    if (_keyStore == null) throw StateError("KeyStore is locked");
    await _flutterSecureStorage!.write(
      key: "key_${_bytesToHex(fingerprint)}",
      value: passphrase,
    );
    notifyListeners();
  }

  Future<void> deleteKeyPassphrase(Uint8List fingerprint) async {
    if (_keyStore == null) throw StateError("KeyStore is locked");
    await _flutterSecureStorage!.delete(key: "key_${_bytesToHex(fingerprint)}");
    notifyListeners();
  }
}

/// A [PgpProvider] that lazily unlocks [KeyStoreHandler.instance], reads the
/// key with [id] from it, and resolves its private key passphrase.
///
/// If the key's private key is encrypted, [tryDecryptPrivateKey] first tries
/// the passphrase remembered for it (if any) and, failing that, prompts the
/// user for one via [showPassphraseInputDialog] using [context]. This means
/// the passphrase dialog is also shown on top of the "initializing" state.
class KeyStorePgpProvider extends PgpProvider {
  final BuildContext context;
  final AppLocalizations appLocalizations;
  final int id;
  final String? email;

  /// Set when this provider aborted the run on purpose (see
  /// [passphraseCancelled]) or because the key store could not be unlocked
  /// (`unlock_<result>`). Used for anonymous outcome statistics only.
  String? abortReason;
  static const passphraseCancelled = "passphraseCancelled";

  /// Total time spent decrypting the private key, including wrong
  /// passphrases. Used for anonymous performance statistics only.
  int decryptMs = 0;

  KeyStorePgpProvider(
    this.context,
    this.appLocalizations, {
    required this.id,
    this.email,
  });

  Key? _key;

  // Decoding a key is expensive, so each key is decoded at most once, in a
  // background isolate, and the result is reused by every method.
  Future<PrivateKey>? _parsedPrivateKey;
  Future<bool>? _publicKeyValid;
  PrivateKey? _decryptedPrivateKey;

  Future<Key> _getKey() async {
    if (_key != null) return _key!;
    final unlock = await KeyStoreHandler.instance.unlock(
      appLocalizations,
      trigger: "exchange",
    );
    if (unlock != UnlockResult.unlocked) {
      abortReason = "unlock_${unlock.name}";
      throw StateError("Key store could not be unlocked: $unlock");
    }
    final store = KeyStoreHandler.instance.keyStore!;
    final key = await (store.select(
      store.keys,
    )..where((k) => k.id.equals(id))).getSingleOrNull();
    if (key == null) {
      throw StateError("Key not found for id $id");
    }
    if (email != null &&
        !(await key.getUserIds(store)).any((u) => u.email == email)) {
      throw StateError(
        "User ID with email $email not found for key $id, cross check failed",
      );
    }

    _parsedPrivateKey = compute(_parsePrivateKey, key.privateData)..ignore();
    _publicKeyValid = compute(_isPublicKeyValidGlobal, key.publicData)
      ..ignore();
    _key = key;

    return key;
  }

  @override
  Future<Uint8List> getPublicKey() async => (await _getKey()).publicData;

  @override
  Future<bool> isPrivateKeyEncrypted() async {
    await _getKey();
    return (await _parsedPrivateKey!).isEncrypted;
  }

  @override
  Future<bool> isPublicKeyValid() async {
    await _getKey();
    return await _publicKeyValid!;
  }

  @override
  Future<bool> tryDecryptPrivateKey(String privateKeyPassphrase) async {
    final key = await _getKey();
    final parsed = await _parsedPrivateKey!;

    if (!parsed.isEncrypted) return true;

    final storedPassphrase = await KeyStoreHandler.instance.getKeyPassphrase(
      key.fingerprint,
    );
    if (storedPassphrase != null && await _unlock(parsed, storedPassphrase)) {
      return true;
    }

    final userIds = await key.getUserIds(KeyStoreHandler.instance.keyStore!);
    if (!context.mounted) return false;
    var attempts = 0;
    final promptStopwatch = Stopwatch()..start();
    final result = await showPassphraseInputDialog(
      context,
      identity: userIds
          .map(
            (u) => UserId(
              name: u.name,
              comment: u.comment,
              email: u.email,
            ).toString(),
          )
          .toList(),
      fingerprint: key.fingerprint,
      validate: (passphrase) async {
        attempts++;
        final decrypted = await _unlock(parsed, passphrase);
        return decrypted ? null : appLocalizations.passphraseInputWrong;
      },
    );
    final submitted = result != null && result.passphrase.isNotEmpty;
    ResearchPoint.trackEvent("passphrasePrompt", {
      "outcome": submitted ? "submitted" : "cancelled",
      "attempts": attempts,
      "storedPassphraseFailed": storedPassphrase != null,
      "remembered": result?.remember ?? false,
      "durationMs": promptStopwatch.elapsedMilliseconds,
      "decryptMs": decryptMs,
    });
    if (result == null || result.passphrase.isEmpty) {
      abortReason = passphraseCancelled;
      throw StateError("Passphrase input cancelled or empty");
    }
    if (result.remember) {
      await KeyStoreHandler.instance.setKeyPassphrase(
        key.fingerprint,
        result.passphrase,
      );
    }
    return true;
  }

  Future<bool> _unlock(PrivateKey parsed, String passphrase) async {
    final stopwatch = Stopwatch()..start();
    final decrypted = await _decryptParsedPrivateKey(parsed, passphrase);
    decryptMs += stopwatch.elapsedMilliseconds;
    if (decrypted == null) return false;
    _decryptedPrivateKey = decrypted;
    return true;
  }

  @override
  Future<Uint8List> signToDetached(
    Uint8List data,
    String? privateKeyPassphrase,
  ) async {
    final key = await _getKey();
    final rawPrivateKey = _decryptedPrivateKey ?? await _parsedPrivateKey!;
    // a decrypted key still reports isEncrypted, so isDecrypted is what tells
    // whether the secret key material is available
    final needsDecryption = !rawPrivateKey.isDecrypted;
    if (needsDecryption && privateKeyPassphrase == null) {
      throw ArgumentError.value(
        key.privateData,
        "privateKey",
        "Private key is encrypted; privateKeyPassphrase is required",
      );
    }
    var privateKey = rawPrivateKey;
    if (needsDecryption) {
      privateKey = await _decryptOrThrow(rawPrivateKey, privateKeyPassphrase!);
      _decryptedPrivateKey = privateKey;
    }
    return _signDetached(data, privateKey);
  }

  @override
  void destroy() {
    _key?.publicData.destroy();
    _key?.privateData.destroy();
    _key = null;
    _parsedPrivateKey = null;
    _publicKeyValid = null;
    _decryptedPrivateKey = null;
  }

  @override
  String toString() => "KeyStorePgpProvider(<REDACTED>)";
}

// These run in background isolates, so they must not capture a provider.
PrivateKey _parsePrivateKey(Uint8List bytes) =>
    PrivateKey(PacketList.decode(bytes));

Future<PrivateKey?> _decryptParsedPrivateKey(
  PrivateKey key,
  String passphrase,
) async {
  try {
    return await _decryptOrThrow(key, passphrase);
  } catch (_) {
    return null;
  }
}

Future<PrivateKey> _decryptOrThrow(PrivateKey key, String passphrase) =>
    Isolate.run(() => key.decrypt(passphrase) as PrivateKey);

Future<Uint8List> _signDetached(Uint8List data, PrivateKey key) => Isolate.run(
  () => Uint8List.fromList(
    OpenPGP.signDetached(OpenPGP.createLiteralMessage(data), [
      key,
    ]).packetList.encode(),
  ),
);

// the provider's own method shadows the top-level function
const _isPublicKeyValidGlobal = isPublicKeyValid;
