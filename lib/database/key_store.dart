import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_helper/material_helper.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/shared.dart';

part 'key_store.g.dart';

@TableIndex(name: "keys_fingerprint", columns: {#fingerprint})
class Keys extends Table {
  IntColumn get id => integer().autoIncrement()();

  BlobColumn get fingerprint => blob()();
  BlobColumn get publicData => blob().unique()();
  BlobColumn get privateData => blob().unique()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

extension KeyExtension on Key {
  List<KeyUserIdsCompanion> generateInsertsForUserIds(List<String> userIds) {
    if (userIds.isEmpty) return const [];
    final parsed = userIds.map((u) => UserId.parse(u));
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
    ("${error.message}${error.details}").contains(
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

  Future<UnlockResult> unlock(AppLocalizations appLocalizations) async {
    final old = _isLocked;
    try {
      try {
        await _unlockOnce(appLocalizations);
      } catch (e) {
        if (!_isAlgorithmChange(e)) rethrow;
        await _unlockOnce(appLocalizations);
      }
      _isLocked = false;
      return UnlockResult.unlocked;
    } catch (e, s) {
      debugPrint("Failed to unlock key store: $e\n$s");
      _keyStore = null;
      _isLocked = true;
      return isDeviceReauthRequired(e)
          ? UnlockResult.deviceReauthRequired
          : UnlockResult.failed;
    } finally {
      if (old != _isLocked) notifyListeners();
    }
  }

  Future<void> _unlockOnce(AppLocalizations appLocalizations) async {
    var nonce = (await _storage(appLocalizations).read(key: "nonce"));
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
  }

  Future<void> deleteKeyPassphrase(Uint8List fingerprint) async {
    if (_keyStore == null) throw StateError("KeyStore is locked");
    await _flutterSecureStorage!.delete(key: "key_${_bytesToHex(fingerprint)}");
  }
}

class KeyStorePgpProvider extends PgpProvider {
  final KeyStore _store;
  final int id;
  final String? email;

  LocalPgpProvider? _internal;
  Future<LocalPgpProvider> _getInternal() async {
    if (_internal != null) return _internal!;
    final key = await (_store.select(
      _store.keys,
    )..where((k) => k.id.equals(id))).getSingleOrNull();
    if (key == null) {
      throw StateError("Key not found for id $id");
    }
    if (email != null &&
        !(await key.getUserIds(_store)).any((u) => u.email == email)) {
      throw StateError(
        "User ID with email $email not found for key $id, cross check failed",
      );
    }
    _internal = LocalPgpProvider(key.publicData, key.privateData);
    return _internal!;
  }

  KeyStorePgpProvider(this._store, {required this.id, this.email});

  @override
  Future<Uint8List> getPublicKey() async =>
      (await _getInternal()).getPublicKey();

  @override
  Future<bool> isPrivateKeyEncrypted() async =>
      (await _getInternal()).isPrivateKeyEncrypted();

  @override
  Future<bool> tryDecryptPrivateKey(String privateKeyPassphrase) async =>
      (await _getInternal()).tryDecryptPrivateKey(privateKeyPassphrase);

  @override
  Future<Uint8List> signToDetached(
    Uint8List data,
    String? privateKeyPassphrase,
  ) async => (await _getInternal()).signToDetached(data, privateKeyPassphrase);

  @override
  void destroy() => _internal?.destroy();

  @override
  String toString() => "KeyStorePgpProvider(internal: $_internal)";
}
