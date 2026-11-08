import 'dart:convert';
import 'dart:math' as math;

import 'package:dart_pg/dart_pg.dart';
// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/common/armor.dart';
// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/enum/armor_type.dart';
// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/enum/revocation_reason_tag.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:icon_craft/icon_craft.dart';
import 'package:intl/intl.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared/shared.dart';

import '../database/contact_store.dart' as contact_store;
import '../database/key_store.dart' as key_store;
import '../key_utils.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../screens/screen_contacts.dart';
import '../screens/screen_run.dart';
import 'add_contact_flow.dart';
import 'backup_code_input.dart';
import 'bottom_sheet_multi_state.dart';
import 'research_point.dart';
import 'snack_bar_manager.dart';

typedef KeyRevocationReason = ({RevocationReasonTag? tag, String description});

final class IdentityContactInterchangeableHandler<T extends Object> {
  final T data;
  const new(this.data)
    : assert(
        data is key_store.Key || data is contact_store.Contact,
        "Data must be either a Key or a Contact",
      );

  int get id {
    if (data is key_store.Key) {
      return (data as key_store.Key).id;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).id;
    }
    throw Exception("Invalid data type");
  }

  Uint8List get publicData {
    if (data is key_store.Key) {
      return (data as key_store.Key).publicData;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).data;
    }
    throw Exception("Invalid data type");
  }

  Uint8List get fingerprint {
    if (data is key_store.Key) {
      return (data as key_store.Key).fingerprint;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).fingerprint;
    }
    throw Exception("Invalid data type");
  }

  bool? get isRevoked {
    if (data is key_store.Key) {
      return (data as key_store.Key).isRevoked;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).isRevoked;
    }
    return null;
  }

  Future<KeyRevocationReason?> revocationReason() async {
    if (data is key_store.Key || data is contact_store.Contact) {
      return await compute(publicKeyRevocationReason, publicData);
    }
    return null;
  }

  DateTime get createdAt {
    if (data is key_store.Key) {
      return (data as key_store.Key).createdAt;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).createdAt;
    }
    throw Exception("Invalid data type");
  }

  DateTime? get expiresAt {
    if (data is key_store.Key) {
      return (data as key_store.Key).expiresAt;
    } else if (data is contact_store.Contact) {
      return (data as contact_store.Contact).expiresAt;
    }
    throw Exception("Invalid data type");
  }

  void addListener(VoidCallback listener) {
    if (data is key_store.Key) {
      key_store.KeyStoreHandler.instance.addListener(listener);
    } else if (data is contact_store.Contact) {
    } else {
      throw Exception("Invalid data type");
    }
  }

  void removeListener(VoidCallback listener) {
    if (data is key_store.Key) {
      key_store.KeyStoreHandler.instance.removeListener(listener);
    } else if (data is contact_store.Contact) {
    } else {
      throw Exception("Invalid data type");
    }
  }

  Future<bool?> hasKeyPassphrase() async {
    if (data is key_store.Key) {
      return key_store.KeyStoreHandler.instance.hasKeyPassphrase(fingerprint);
    }
    return null;
  }

  bool get exportableAsBackup => data is key_store.Key;

  Future<void> export({
    bool asBackup = false,
    List<UserIdInterchangeableHandler>? userIds,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final appLocalizations = AppLocalizations.of(context);
    final exportAsBackup = data is key_store.Key && asBackup;
    final exportBytes = switch (data) {
      final key_store.Key key => key.privateData,
      final contact_store.Contact contact => contact.data,
      _ => throw Exception("Invalid data type"),
    };
    final publicBytes = switch (data) {
      final key_store.Key key => key.publicData,
      final contact_store.Contact contact => contact.data,
      _ => throw Exception("Invalid data type"),
    };

    final userIdsToFileName =
        userIds?.map((u) => u.name?.trim().replaceAll(" ", "_")).join("-") ??
        "Unknown";

    if (exportAsBackup) {
      if (!context.mounted) return;
      final backupCode = ValueNotifier<String?>(null);
      final confirmedFuture = showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        clipBehavior: Clip.antiAlias,
        builder: (context) => BackupCodeOutput(backupCode: backupCode),
      );
      final backup = await backupFormat([
        (type: ArmorType.publicKey, bytes: publicBytes),
        (type: ArmorType.privateKey, bytes: exportBytes),
      ]);
      backupCode.value = backup.backupCode;

      final confirmed = await confirmedFuture;
      if (confirmed != true) {
        _trackExport("backup", "cancelled");
        return;
      }
      if (context.mounted) Navigator.of(context).pop();
      try {
        final path = await FilePicker.saveFile(
          fileName: "$userIdsToFileName.asc",
          bytes: utf8.encode(backup.data),
        );
        _trackExport("backup", path != null ? "saved" : "cancelled");
        if (path != null) {
          SnackBarManager.showSnackBarOn(
            messenger,
            appLocalizations.identityBackupExported,
          );
        }
      } catch (_) {
        _trackExport("backup", "failed");
        SnackBarManager.showSnackBarOn(
          messenger,
          appLocalizations.identityBackupExportFailed,
        );
      }
    } else {
      if (context.mounted) Navigator.of(context).pop();
      try {
        final path = await FilePicker.saveFile(
          fileName: "$userIdsToFileName.pgp",
          bytes: exportBytes,
        );
        _trackExport("plain", path != null ? "saved" : "cancelled");
        if (path != null) {
          SnackBarManager.showSnackBarOn(
            messenger,
            appLocalizations.identityKeyExported,
          );
        }
      } catch (_) {
        _trackExport("plain", "failed");
        SnackBarManager.showSnackBarOn(
          messenger,
          appLocalizations.identityKeyExportFailed,
        );
      }
    }
  }

  void _trackExport(String format, String outcome) =>
      ResearchPoint.trackEvent("keyExport", {
        "target": data is key_store.Key ? "identity" : "contact",
        "format": format,
        "outcome": outcome,
      });

  Future<String> updatePublicKey(
    BuildContext context, {
    required String email,
  }) async {
    if (data is! key_store.Key && data is! contact_store.Contact) {
      throw Exception("Invalid key data");
    }

    final appLocalizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (_) => BottomSheetMultiState(child: null),
    );

    final hkpKeyServers =
        prefs
            ?.getStringList("hkp_key_servers")
            ?.map(
              (s) => UserId.commonHkpKeyServers.firstWhereOrNull(
                (c) => c.host == s,
              ),
            )
            .whereType<HkpKeyServer>()
            .toList() ??
        UserId.defaultHkpKeyServers;
    final update = await compute(
      (data) => UserId(email: data.email).fetchKeyFromPublic(
        KeyFetchHttpClient(),
        fingerprints: [data.fingerprint],
        hkpKeyServers: hkpKeyServers,
      ),
      (email: email, fingerprint: fingerprint),
    );
    if (update == null) {
      _trackUpdate("noSource");
      throw Exception("No source available");
    }

    if (!publicKeysMatch(update.keys.first.bytes, publicData)) {
      _trackUpdate("mismatch");
      throw Exception("Public key mismatch");
    }

    final newParsedKey = await compute(
      publicKeyFromBytes,
      update.keys.first.bytes,
    );
    final users = newParsedKey.users
        .map((u) => UserId.tryParse(u.userID)?.toString())
        .whereType<String>()
        .toList();

    if (data is key_store.KeyStore) {
      final keyStore = key_store.KeyStoreHandler.instance.keyStore!;
      await keyStore.updateKey(
        key_store.KeysCompanion(
          id: .new(id),
          fingerprint: .new(newParsedKey.fingerprint),
          publicData: .new(update.keys.first.bytes),
          privateData: .new((data as key_store.Key).privateData),
          isRevoked: .new(isPublicKeyDataRevoked(update.keys.first.bytes)),
          createdAt: .new(newParsedKey.creationTime),
          expiresAt: .new(keyExpirationTime(newParsedKey)),
        ),
        users,
      );
    } else {
      contactStore.updateContact(
        contact_store.ContactsCompanion(
          id: .new(id),
          fingerprint: .new(newParsedKey.fingerprint),
          data: .new(update.keys.first.bytes),
          isRevoked: .new(isPublicKeyDataRevoked(update.keys.first.bytes)),
          createdAt: .new(newParsedKey.creationTime),
          expiresAt: .new(keyExpirationTime(newParsedKey)),
        ),
        users,
      );
    }

    _trackUpdate("updated");
    return keyFetchSourceTitle(
      appLocalizations,
      origin: update.origin,
      originHost: update.originHost,
    ).title;
  }

  void _trackUpdate(String outcome) => ResearchPoint.trackEvent("keyUpdate", {
    "target": data is key_store.Key ? "identity" : "contact",
    "outcome": outcome,
  });

  Future<void> delete() async {
    if (data is key_store.Key) {
      final keyStore = key_store.KeyStoreHandler.instance.keyStore!;
      await keyStore.transaction(() async {
        await (keyStore.delete(
          keyStore.keys,
        )..where((c) => c.id.equals(id))).go();
        await (keyStore.delete(
          keyStore.keyUserIds,
        )..where((c) => c.parent.equals(id))).go();
      });
      await key_store.KeyStoreHandler.instance.deleteKeyPassphrase(fingerprint);
    } else if (data is contact_store.Contact) {
      await contactStore.transaction(() async {
        await (contactStore.delete(
          contactStore.contacts,
        )..where((c) => c.id.equals(id))).go();
        await (contactStore.delete(
          contactStore.contactUserIds,
        )..where((c) => c.parent.equals(id))).go();
      });
    } else {
      throw Exception("Invalid data type");
    }
    ResearchPoint.trackEvent("keyDeleted", {
      "target": data is key_store.Key ? "identity" : "contact",
    });
  }

  Future<void> deleteKeyPassphrase() async {
    if (data is key_store.Key) {
      await key_store.KeyStoreHandler.instance.deleteKeyPassphrase(fingerprint);
    } else {
      throw Exception("Invalid data type");
    }
  }
}

Future<({String backupCode, String data})> backupFormat(
  List<({ArmorType type, Uint8List bytes})> exportBytes,
) async {
  final rng = math.Random.secure();
  final backupCode = StringBuffer();
  for (var i = 0; i < 24; i++) {
    if (i % 4 == 0 && i != 0) backupCode.write("-");
    backupCode.write(
      backupCodeCharacters[rng.nextInt(backupCodeCharacters.length)],
    );
  }

  String brandingReplacement(String input) => input.replaceFirst(
    RegExp(r"^Comment:.*$", multiLine: true),
    "Comment: Exported from PGPtouch",
  );
  String exportedBytesFormat(
    List<({ArmorType type, Uint8List bytes})> exportBytes,
  ) {
    final parts = exportBytes.map(
      (b) => brandingReplacement(Armor.encode(b.type, b.bytes)).trim(),
    );
    return "${parts.join("\n")}\n";
  }

  final backup = brandingReplacement(
    await compute(
      (data) => OpenPGP.encryptCleartext(
        data,
        passwords: [backupCode.toString()],
      ).armor(),
      exportedBytesFormat(exportBytes),
    ),
  ).replaceFirst("\n\n", "\nBackupVersion: 2\n\n");

  return (backupCode: backupCode.toString(), data: backup);
}

class BackupCodeOutput extends StatefulWidget {
  final ValueNotifier<String?> backupCode;
  const new({super.key, required this.backupCode});

  @override
  State<BackupCodeOutput> createState() => _BackupCodeOutputState();
}

class _BackupCodeOutputState extends State<BackupCodeOutput> {
  var copied = false;

  @override
  void initState() {
    super.initState();
    widget.backupCode.addListener(onUpdate);
  }

  @override
  void dispose() {
    widget.backupCode.removeListener(onUpdate);
    super.dispose();
  }

  void onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final textTheme = TextTheme.of(context);

    final backupCodeParts = widget.backupCode.value?.split("-");
    final backupCodeFormatted = StringBuffer();
    if (backupCodeParts != null) {
      for (var i = 0; i < backupCodeParts.length; i++) {
        backupCodeFormatted
          ..write(backupCodeParts[i])
          ..write(i.isEven ? " - " : " -\n");
      }
    }

    Widget content() => Padding(
      padding:
          MediaQuery.viewInsetsOf(context) +
          MediaQuery.paddingOf(context) +
          const EdgeInsets.all(16).copyWith(top: 14, bottom: 8),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          Text(
            hyphenate(appLocalizations.backupCodeShowPrompt),
            textAlign: .justify,
          ),
          SizedBox(height: 20),
          Text(
            backupCodeFormatted.toString().trim(),
            style: textTheme.headlineSmall!.googleSansCode,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisSize: .max,
            children: [
              Expanded(child: SizedBox()),
              FilledButton.icon(
                onPressed: () {
                  copyDataInt(context, widget.backupCode.value, false);
                  copied = true;
                  if (mounted) setState(() {});
                },
                icon: Icon(Icons.copy),
                label: Text(appLocalizations.backupCodeShowCopy),
              ),
              SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: copied
                    ? () => Navigator.of(context).pop(true)
                    : null,
                label: Text(appLocalizations.passphraseInputContinue),
              ),
            ],
          ),
        ],
      ),
    );

    return BottomSheetMultiState(
      child: widget.backupCode.value != null ? content() : null,
    );
  }
}

final class UserIdInterchangeableHandler<T extends Object> {
  final T data;
  const new(this.data)
    : assert(
        data is key_store.KeyUserId ||
            data is contact_store.ContactUserId ||
            data is UserId,
        "Data must be either a Key, a Contact or a UserId",
      );

  int get id {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).id;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).id;
    }
    throw Exception("Invalid data type");
  }

  String? get name {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).name;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).name;
    } else if (data is UserId) {
      return (data as UserId).name;
    }
    throw Exception("Invalid data type");
  }

  String? get comment {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).comment;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).comment;
    } else if (data is UserId) {
      return (data as UserId).comment;
    }
    throw Exception("Invalid data type");
  }

  String get email {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).email;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).email;
    } else if (data is UserId) {
      return (data as UserId).email;
    }
    throw Exception("Invalid data type");
  }
}

extension KeyUserIdToUserIdInterchangeableHandlerExtension
    on key_store.KeyUserId {
  UserIdInterchangeableHandler<key_store.KeyUserId> toInterchangeable() =>
      UserIdInterchangeableHandler<key_store.KeyUserId>(this);
}

extension KeyUserIdListToUserIdInterchangeableHandlerExtension
    on List<key_store.KeyUserId> {
  List<UserIdInterchangeableHandler<key_store.KeyUserId>> toInterchangeable() =>
      map(UserIdInterchangeableHandler<key_store.KeyUserId>.new).toList();
}

extension ContactUserIdToUserIdInterchangeableHandlerExtension
    on contact_store.ContactUserId {
  UserIdInterchangeableHandler<contact_store.ContactUserId>
  toInterchangeable() =>
      UserIdInterchangeableHandler<contact_store.ContactUserId>(this);
}

extension ContactUserIdListToUserIdInterchangeableHandlerExtension
    on List<contact_store.ContactUserId> {
  List<UserIdInterchangeableHandler<contact_store.ContactUserId>>
  toInterchangeable() =>
      map(UserIdInterchangeableHandler<contact_store.ContactUserId>.new)
          .toList();
}

class IdentityTile<K extends Object, U extends Object> extends StatefulWidget {
  final IdentityContactInterchangeableHandler<K> keyData;
  final List<UserIdInterchangeableHandler<U>> userIds;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate;
  final VoidCallback? onDeleted;

  const new({
    super.key,
    required this.keyData,
    required this.userIds,
    this.onTap,
    this.onUpdate,
    this.onDeleted,
  });

  @override
  State<IdentityTile> createState() => _IdentityTileState();
}

class _IdentityTileState extends State<IdentityTile> {
  bool? _passphraseIsStored;
  final _parsedKey = ValueNotifier<PublicKey?>(null);
  final _revocationReason = ValueNotifier<KeyRevocationReason?>(null);

  @override
  void initState() {
    super.initState();
    _parseKey(widget.keyData.publicData);
    widget.keyData.addListener(onUpdate);
  }

  @override
  void dispose() {
    widget.keyData.removeListener(onUpdate);
    super.dispose();
  }

  Future<void> onUpdate() async {
    _passphraseIsStored = await widget.keyData.hasKeyPassphrase();
    if (mounted) setState(() {});
  }

  Future<void> _parseKey(Uint8List keyData) async {
    _passphraseIsStored = await widget.keyData.hasKeyPassphrase();
    if (mounted) setState(() {});

    _parsedKey.value = await compute(publicKeyFromBytes, keyData);
    _revocationReason.value = await widget.keyData.revocationReason();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant IdentityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyData.publicData != widget.keyData.publicData) {
      _parseKey(widget.keyData.publicData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);

    final isExpired =
        widget.keyData.expiresAt != null &&
        widget.keyData.expiresAt!.isBefore(DateTime.now());
    final isRevoked = widget.keyData.isRevoked ?? false;

    final fgColor = isExpired || isRevoked
        ? colorScheme.onErrorContainer
        : null;
    final tileColor = isExpired || isRevoked
        ? colorScheme.errorContainer
        : null;

    final users = widget.userIds
        .map((user) => IdentityTileUserIdChip(user: user))
        .toList();

    void showDetailScreen() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => IdentityDetailScreen(
        users: users,
        userIds: widget.userIds,
        parsedKey: _parsedKey,
        keyData: widget.keyData,
        passphraseIsStored: _passphraseIsStored,
        isExpired: isExpired,
        isRevoked: isRevoked,
        revocationReason: _revocationReason,
        onUpdate: widget.onUpdate,
        onDeleted: widget.onDeleted,
      ),
    );

    return MaterialListTile(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fgColor),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            crossAxisAlignment: .center,
            children: [
              ...users,
              if (isExpired || isRevoked)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          child: Icon(
                            Icons.warning_amber_outlined,
                            size: textTheme.bodySmall?.fontSize,
                            color: fgColor,
                          ),
                          alignment: .middle,
                        ),
                        TextSpan(text: " "),
                        TextSpan(
                          text: isExpired
                              ? appLocalizations.identityExpired
                              : appLocalizations.identityRevoked,
                        ),
                      ],
                    ),
                    style: textTheme.bodySmall!.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
      subtitle: Builder(
        builder: (context) => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(
                      Icons.edit_calendar,
                      size: textTheme.bodySmall?.fontSize,
                      color: fgColor,
                    ),
                    alignment: .middle,
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: DateFormat.yMMMd(appLocalizations.localeName)
                        .format(widget.keyData.createdAt),
                  ),
                  TextSpan(text: " " * 4),
                  WidgetSpan(
                    child: Icon(
                      Icons.event_busy,
                      size: textTheme.bodySmall?.fontSize,
                      color: fgColor,
                    ),
                    alignment: .middle,
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: widget.keyData.expiresAt != null
                        ? DateFormat.yMMMd(appLocalizations.localeName)
                              .format(widget.keyData.expiresAt!)
                        : appLocalizations.identityExpirationNever,
                  ),
                  if (_passphraseIsStored == true) ...[
                    TextSpan(text: " " * 4),
                    WidgetSpan(
                      child: Icon(
                        Icons.bookmark,
                        size: textTheme.bodySmall?.fontSize,
                        color:
                            (colorScheme.brightness == .light
                                    ? Colors.lightBlue
                                    : Colors.lightBlueAccent)
                                .harmonizeWith(colorScheme.primary),
                      ),
                      alignment: .middle,
                    ),
                    TextSpan(text: " "),
                    TextSpan(
                      text: appLocalizations.identityPassphraseRemembered,
                      style: textTheme.bodySmall?.copyWith(
                        color:
                            (colorScheme.brightness == .light
                                    ? Colors.lightBlue
                                    : Colors.lightBlueAccent)
                                .harmonizeWith(colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
              style: textTheme.bodySmall!.copyWith(color: fgColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              () {
                final text = formatFingerprint(widget.keyData.fingerprint)
                    .replaceAll(" ", "")
                    .replaceFirst("\n", "")
                    .split("");
                return "${text.sublist(0, (text.length / 2).ceil()).join()}\u{200B}${text.sublist((text.length / 2).ceil()).join()}";
              }(),
              style: textTheme.bodySmall!.googleSansCode.copyWith(
                color: fgColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ),
      tileColor: tileColor,
      trailing: widget.onTap != null && !(isExpired || isRevoked)
          ? Icon(Icons.chevron_right)
          : null,
      isThreeLine: true,
      onTap: !(isExpired || isRevoked) ? widget.onTap : null,
      onLongPress: showDetailScreen,
    );
  }
}

class IdentityDetailScreen<K extends Object> extends StatefulWidget {
  final List<IdentityTileUserIdChip> users;
  final List<UserIdInterchangeableHandler> userIds;
  final ValueNotifier<PublicKey?> parsedKey;
  final IdentityContactInterchangeableHandler<K> keyData;
  final bool? passphraseIsStored;
  final bool isExpired;
  final bool isRevoked;
  final ValueNotifier<KeyRevocationReason?> revocationReason;
  final VoidCallback? onUpdate;
  final VoidCallback? onDeleted;

  const new({
    super.key,
    required this.users,
    required this.userIds,
    required this.parsedKey,
    required this.keyData,
    required this.passphraseIsStored,
    required this.isExpired,
    required this.isRevoked,
    required this.revocationReason,
    required this.onUpdate,
    required this.onDeleted,
  });

  @override
  State<IdentityDetailScreen<K>> createState() =>
      _IdentityDetailScreenState<K>();
}

class _IdentityDetailScreenState<K extends Object>
    extends State<IdentityDetailScreen<K>> {
  @override
  void initState() {
    super.initState();
    widget.parsedKey.addListener(onUpdate);
    widget.revocationReason.addListener(onUpdate);
  }

  @override
  void dispose() {
    widget.parsedKey.removeListener(onUpdate);
    widget.revocationReason.removeListener(onUpdate);
    super.dispose();
  }

  void onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colorScheme = ColorScheme.of(context);
    final appLocalizations = AppLocalizations.of(context);

    Widget content() => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height / 4 * 3),
      child: SingleChildScrollView(
        child: Padding(
          padding:
              MediaQuery.viewInsetsOf(context) +
              MediaQuery.paddingOf(context) +
              EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: .min,
            children: [
              MaterialListTile(
                title: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: widget.users.toList(),
                ),
                backgroundStyle: .lightened,
              ),
              ...MaterialListTile.group(
                headline: MaterialListTileHeadline(
                  Text(appLocalizations.identityDetailsHeadline),
                ),
                [
                  if (widget.isRevoked && widget.revocationReason.value != null)
                    MaterialListTile(
                      leading: Icon(
                        Icons.block,
                        color: colorScheme.onErrorContainer,
                      ),
                      title: Text(appLocalizations.identityRevoked),
                      subtitle:
                          widget.revocationReason.value!.description.isNotEmpty
                          ? Text(
                              widget.revocationReason.value!.description,
                              maxLines: 2,
                            )
                          : null,
                      trailing: widget.revocationReason.value!.tag != null
                          ? Text(switch (widget.revocationReason.value!.tag!) {
                              RevocationReasonTag.noReason =>
                                appLocalizations
                                    .identityRevocationReasonNoReason,
                              RevocationReasonTag.keySuperseded =>
                                appLocalizations
                                    .identityRevocationReasonKeySuperseded,
                              RevocationReasonTag.keyCompromised =>
                                appLocalizations
                                    .identityRevocationReasonKeyCompromised,
                              RevocationReasonTag.keyRetired =>
                                appLocalizations
                                    .identityRevocationReasonKeyRetired,
                              RevocationReasonTag.userIDInvalid =>
                                appLocalizations
                                    .identityRevocationReasonUserIdInvalid,
                            })
                          : null,
                      tileColor: colorScheme.errorContainer,
                      textColor: colorScheme.onErrorContainer,
                      backgroundStyle: .lightened,
                    ),
                  MaterialListTile(
                    leading: Icon(Icons.edit_calendar),
                    title: Text(appLocalizations.identityCreation),
                    subtitle: Text(
                      DateFormat.yMMMd(appLocalizations.localeName)
                          .add_Hm()
                          .format(widget.keyData.createdAt),
                    ),
                    backgroundStyle: .lightened,
                  ),
                  MaterialListTile(
                    leading: Icon(
                      Icons.event_busy,
                      color: widget.isExpired
                          ? colorScheme.onErrorContainer
                          : null,
                    ),
                    title: Text(appLocalizations.identityExpiration),
                    subtitle: Text(
                      widget.keyData.expiresAt != null
                          ? DateFormat.yMMMd(appLocalizations.localeName)
                                .add_Hm()
                                .format(widget.keyData.expiresAt!)
                          : appLocalizations.identityExpirationNever,
                    ),
                    tileColor: widget.isExpired
                        ? colorScheme.errorContainer
                        : null,
                    textColor: widget.isExpired
                        ? colorScheme.onErrorContainer
                        : null,
                    backgroundStyle: .lightened,
                  ),
                ],
              ),
              ...MaterialListTile.group([
                MaterialListTile(
                  leading: Icon(Icons.functions),
                  title: Text(appLocalizations.identityKeyAlgorithm),
                  subtitle: Text(switch (widget.parsedKey.value!.keyAlgorithm) {
                    .x25519 || .ed25519 || .eddsaLegacy => "Curve25519",
                    .rsaEncryptSign || .rsaEncrypt || .rsaSign => "RSA",
                    _ => appLocalizations.unknown,
                  }),
                  backgroundStyle: .lightened,
                ),
                if (widget.parsedKey.value!.keyAlgorithm
                    case .rsaEncryptSign || .rsaEncrypt || .rsaSign)
                  MaterialListTile(
                    leading: Icon(Icons.sports_mma),
                    title: Text(appLocalizations.identityKeyStrength),
                    subtitle: Text(
                      widget.parsedKey.value!.keyStrength.toString(),
                    ),
                    backgroundStyle: .lightened,
                  ),
                MaterialListTile(
                  leading: Icon(Icons.numbers),
                  title: Text(appLocalizations.identityKeyVersion),
                  subtitle: Text(widget.parsedKey.value!.version.toString()),
                  backgroundStyle: .lightened,
                ),
              ]),
              ...MaterialListTile.group([
                MaterialListTile(
                  leading: Icon(Icons.vpn_key),
                  title: Text(appLocalizations.identityKeyId),
                  subtitle: Builder(
                    builder: (context) => Text(
                      widget.parsedKey.value!.keyID
                          .map((e) => e.toRadixString(16))
                          .join(),
                      style: DefaultTextStyle.of(context).style.googleSansCode,
                    ),
                  ),
                  onLongPress: () => copyDataInt(
                    context,
                    widget.parsedKey.value!.keyID
                        .map((e) => e.toRadixString(16))
                        .join(),
                    false,
                  ),
                  backgroundStyle: .lightened,
                ),
                MaterialListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text(appLocalizations.identityFingerprint),
                  subtitle: FittedBox(
                    fit: .scaleDown,
                    alignment: .centerStart,
                    child: Builder(
                      builder: (context) => Text(
                        formatFingerprint(widget.keyData.fingerprint),
                        style: DefaultTextStyle.of(context)
                            .style
                            .googleSansCode,
                      ),
                    ),
                  ),
                  onLongPress: () => copyDataInt(
                    context,
                    formatFingerprint(widget.keyData.fingerprint),
                    false,
                  ),
                  backgroundStyle: .lightened,
                ),
              ]),
              if (widget.passphraseIsStored != null)
                MaterialListTile(
                  leading: Icon(
                    widget.passphraseIsStored == true
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.passphraseIsStored != null
                        ? widget.passphraseIsStored!
                              ? Colors.lightBlueAccent.harmonizeWith(
                                  colorScheme.primary,
                                )
                              : null
                        : null,
                  ),
                  title: Text(
                    widget.passphraseIsStored == true
                        ? appLocalizations.identityPassphraseStored
                        : appLocalizations.identityPassphraseNotStored,
                  ),
                  backgroundStyle: .lightened,
                ),
              ...MaterialListTile.group(
                headline: MaterialListTileHeadline(
                  Text(appLocalizations.identityActionsHeadline),
                ),
                [
                  MaterialListTile(
                    leading: Icon(Icons.file_upload_outlined),
                    title: Text(appLocalizations.identityExportKey),
                    backgroundStyle: .lightened,
                    onTap: () => widget.keyData.export(
                      userIds: widget.userIds,
                      context: context,
                    ),
                  ),
                  if (widget.keyData.exportableAsBackup)
                    MaterialListTile(
                      leading: IconCraft(
                        Icon(Icons.file_upload_outlined),
                        Icon(Icons.cloud),
                        alignment: Alignment.bottomRight,
                        decoration: IconDecoration(
                          border: IconBorder(
                            color: colorScheme.brightness == Brightness.light
                                ? colorScheme.surfaceContainerLowest
                                : colorScheme.surfaceBright,
                          ),
                        ),
                      ),
                      title: Text(appLocalizations.identityExportBackup),
                      backgroundStyle: .lightened,
                      onTap: () => widget.keyData.export(
                        asBackup: true,
                        userIds: widget.userIds,
                        context: context,
                      ),
                    ),
                  MaterialListTile(
                    leading: Icon(Icons.sync),
                    title: Text(appLocalizations.identityUpdateKey),
                    backgroundStyle: .lightened,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final origin = await widget.keyData.updatePublicKey(
                          context,
                          email: widget.userIds.first.email,
                        );
                        SnackBarManager.showSnackBarOn(
                          messenger,
                          appLocalizations.identityPublicKeyUpdated(origin),
                        );
                        widget.onUpdate?.call();
                      } catch (e) {
                        SnackBarManager.showSnackBarOn(
                          messenger,
                          e.toString().contains("available")
                              ? appLocalizations.identityPublicKeyUpdateNoSource
                              : appLocalizations.identityPublicKeyUpdateFailed,
                        );
                      } finally {
                        if (context.mounted) {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) navigator.pop();
                          if (navigator.canPop()) navigator.pop();
                        }
                      }
                    },
                  ),
                  if (widget.passphraseIsStored == true)
                    MaterialListTile(
                      leading: Icon(Icons.psychology_alt_outlined),
                      title: Text(
                        appLocalizations.identityDeleteStoredPassphrase,
                      ),
                      backgroundStyle: .lightened,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        try {
                          await widget.keyData.deleteKeyPassphrase();
                          SnackBarManager.showSnackBarOn(
                            messenger,
                            appLocalizations.identityStoredPassphraseRemoved,
                          );
                        } catch (_) {
                          SnackBarManager.showSnackBarOn(
                            messenger,
                            appLocalizations
                                .identityStoredPassphraseRemoveFailed,
                          );
                        }
                      },
                    ),
                  MaterialListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text(appLocalizations.identityDeleteKey),
                    backgroundStyle: .lightened,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      try {
                        await widget.keyData.delete();
                        widget.onDeleted?.call();
                        SnackBarManager.showSnackBarOn(
                          messenger,
                          appLocalizations.identityDeleted,
                        );
                      } catch (_) {
                        SnackBarManager.showSnackBarOn(
                          messenger,
                          appLocalizations.identityDeleteFailed,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return BottomSheetMultiState(
      child: widget.parsedKey.value != null ? content() : null,
    );
  }
}

class IdentityTileUserIdChip<U extends Object> extends StatelessWidget {
  final UserIdInterchangeableHandler<U> user;

  const new({super.key, required this.user});

  void _showDetailsDialog({
    required BuildContext context,
    required TextTheme textTheme,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    builder: (context) {
      final appLocalizations = AppLocalizations.of(context);
      return Padding(
        padding:
            MediaQuery.viewInsetsOf(context) +
            MediaQuery.paddingOf(context) +
            EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: .min,
          children: MaterialListTile.group([
            MaterialListTile(
              leading: SizedBox.square(
                dimension: 48,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: IdentityTileAvatar(user: user),
                ),
              ),
              title: GestureDetector(
                child: Text(
                  user.name ?? appLocalizations.valueMissing,
                  maxLines: 5,
                  overflow: .ellipsis,
                  style: textTheme.headlineSmall!
                      .copyWith(fontVariations: [FontVariation.width(115)])
                      .googleSansFlexExt(weight: 550, roundness: 55),
                ),
              ),
              subtitle: user.comment != null
                  ? Builder(
                      builder: (context) => Text(
                        appLocalizations.identityComment(user.comment!),
                        maxLines: 2,
                        style: DefaultTextStyle.of(context).style
                            .copyWith(
                              fontVariations: [
                                FontVariation.width(110),
                                FontVariation("GRAD", 60),
                              ],
                            )
                            .googleSansFlexExt(roundness: 55),
                      ),
                    )
                  : null,
              onLongPress: () {
                copyDataInt(
                  context,
                  "${user.name ?? appLocalizations.valueMissing} ${user.comment != null ? "(${user.comment})" : ""}"
                      .trim(),
                  false,
                );
              },
              backgroundStyle: .lightened,
            ),
            MaterialListTile(
              leading: Icon(Icons.email),
              title: Text(user.email, maxLines: 1),
              backgroundStyle: .lightened,
              onTap: () => launchUrl(Uri(scheme: "mailto", path: user.email)),
              onLongPress: () =>
                  Clipboard.setData(ClipboardData(text: user.email)),
            ),
          ]),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    var parentFgColor = DefaultTextStyle.of(context).style.color;
    if (parentFgColor == colorScheme.onSurface) parentFgColor = null;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => _showDetailsDialog(context: context, textTheme: textTheme),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(color: parentFgColor ?? colorScheme.outline),
          ),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: 1,
                bottom: 1,
                start: 1,
              ),
              child: SizedBox.square(
                dimension: 26,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: IdentityTileAvatar(user: user, radius: 16),
                ),
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "${user.name ?? user.email}${user.comment != null ? " ${AppLocalizations.of(context).identityComment(user.comment!)}" : ""}",
                style: textTheme.labelLarge?.copyWith(color: parentFgColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class IdentityTileAvatar<U extends Object> extends StatelessWidget {
  final UserIdInterchangeableHandler<U> user;
  final double? radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const new({
    super.key,
    required this.user,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Builder(
        builder: (context) => Text(
          user.email[0].toUpperCase(),
          style: DefaultTextStyle.of(context).style.googleSansCode,
        ),
      ),
    );
  }
}

Future<void> copyDataInt(
  BuildContext context,
  String? data, [
  bool showSnackBar = true,
]) async {
  if (data == null) return;
  await Clipboard.setData(ClipboardData(text: data));
  if (context.mounted && showSnackBar) {
    SnackBarManager.showSnackBar(
      context,
      MaterialHelperLocalizations.of(context)!.copiedToClipboard,
    );
  }
}
