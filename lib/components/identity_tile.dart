import 'package:dart_pg/dart_pg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';

import 'package:material_helper/material_helper.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/screen_run.dart';
import 'package:shared/shared.dart';

import '../database/key_store.dart' as key_store;
import '../database/contact_store.dart' as contact_store;

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
    } else {
      return null;
    }
  }

  Future<void> delete() async {
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
  }

  Future<void> deleteKeyPassphrase() async {
    if (data is key_store.Key) {
      await key_store.KeyStoreHandler.instance.deleteKeyPassphrase(fingerprint);
    } else {
      throw Exception("Invalid data type");
    }
  }
}

final class UserIdInterchangeableHandler<T extends Object> {
  final T data;
  const new(this.data)
    : assert(
        data is key_store.KeyUserId || data is contact_store.ContactUserId,
        "Data must be either a Key or a Contact",
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
    }
    throw Exception("Invalid data type");
  }

  String? get comment {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).comment;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).comment;
    }
    throw Exception("Invalid data type");
  }

  String get email {
    if (data is key_store.KeyUserId) {
      return (data as key_store.KeyUserId).email;
    } else if (data is contact_store.ContactUserId) {
      return (data as contact_store.ContactUserId).email;
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
      map(
        (keyUserId) =>
            UserIdInterchangeableHandler<key_store.KeyUserId>(keyUserId),
      ).toList();
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
  toInterchangeable() => map(
    (contactUserId) =>
        UserIdInterchangeableHandler<contact_store.ContactUserId>(
          contactUserId,
        ),
  ).toList();
}

class IdentityTile<K extends Object, U extends Object> extends StatefulWidget {
  final IdentityContactInterchangeableHandler<K> keyData;
  final List<UserIdInterchangeableHandler<U>> userIds;
  final VoidCallback? onTap;
  final VoidCallback? onIdentityDeleted;

  const new({
    super.key,
    required this.keyData,
    required this.userIds,
    this.onTap,
    this.onIdentityDeleted,
  });

  @override
  State<IdentityTile> createState() => _IdentityTileState();
}

class _IdentityTileState extends State<IdentityTile> {
  PublicKey? _parsedKey;
  bool? _passphraseIsStored;

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

  void onUpdate() async {
    _passphraseIsStored = await widget.keyData.hasKeyPassphrase();
    if (mounted) setState(() {});
  }

  void _parseKey(Uint8List keyData) async {
    _parsedKey = await compute((_) => publicKeyFromBytes(keyData), null);
    _passphraseIsStored = await widget.keyData.hasKeyPassphrase();
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

    final users = widget.userIds.map(
      (user) => IdentityTileUserIdChip(user: user),
    );

    void showDetailScreen() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => IdentityDetailScreen(
        users: users,
        parsedKey: _parsedKey,
        keyData: widget.keyData,
        passphraseIsStored: _passphraseIsStored,
        onIdentityDeleted: widget.onIdentityDeleted,
      ),
    );

    return MaterialListTile(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 2, runSpacing: 2, children: users.toList()),
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
                    ),
                    alignment: .middle,
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: _parsedKey?.creationTime != null
                        ? DateFormat.yMMMd(appLocalizations.localeName)
                              .add_Hm()
                              .format(_parsedKey!.creationTime)
                        : appLocalizations.valueMissing,
                  ),
                  TextSpan(text: " " * 4),
                  WidgetSpan(
                    child: Icon(
                      Icons.event_busy,
                      size: textTheme.bodySmall?.fontSize,
                    ),
                    alignment: .middle,
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: _parsedKey != null
                        ? _parsedKey!.expirationTime != null
                              ? DateFormat.yMMMd(appLocalizations.localeName)
                                    .add_Hm()
                                    .format(_parsedKey!.expirationTime!)
                              : appLocalizations.identityExpirationNever
                        : appLocalizations.valueMissing,
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
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                formatFingerprint(widget.keyData.fingerprint)
                    .replaceAll(" ", "")
                    .replaceFirst("\n", ""),
                style: textTheme.bodySmall!.googleSansCode,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: widget.onTap != null ? Icon(Icons.chevron_right) : null,
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: _parsedKey != null ? () => showDetailScreen() : null,
    );
  }
}

class IdentityDetailScreen<K extends Object> extends StatelessWidget {
  final Iterable<IdentityTileUserIdChip> _users;
  final PublicKey? _parsedKey;
  final IdentityContactInterchangeableHandler<K> _keyData;
  final bool? _passphraseIsStored;
  final VoidCallback? _onIdentityDeleted;

  const new({
    super.key,
    required this._users,
    required this._parsedKey,
    required this._keyData,
    required this._passphraseIsStored,
    required this._onIdentityDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colorScheme = ColorScheme.of(context);
    final appLocalizations = AppLocalizations.of(context);

    return ConstrainedBox(
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
                  children: _users.toList(),
                ),
                backgroundStyle: .lightened,
              ),
              ...MaterialListTile.group(
                headline: MaterialListTileHeadline(
                  Text(appLocalizations.identityDetailsHeadline),
                ),
                [
                  MaterialListTile(
                    leading: Icon(Icons.edit_calendar),
                    title: Text(appLocalizations.identityCreation),
                    subtitle: Text(
                      _parsedKey?.creationTime != null
                          ? DateFormat.yMMMd(appLocalizations.localeName)
                                .add_Hm()
                                .format(_parsedKey!.creationTime)
                          : appLocalizations.valueMissing,
                    ),
                    backgroundStyle: .lightened,
                  ),
                  MaterialListTile(
                    leading: Icon(Icons.event_busy),
                    title: Text(appLocalizations.identityExpiration),
                    subtitle: Text(
                      _parsedKey != null
                          ? _parsedKey!.expirationTime != null
                                ? DateFormat.yMMMd(appLocalizations.localeName)
                                      .add_Hm()
                                      .format(_parsedKey!.expirationTime!)
                                : appLocalizations.identityExpirationNever
                          : appLocalizations.valueMissing,
                    ),
                    backgroundStyle: .lightened,
                  ),
                ],
              ),
              ...MaterialListTile.group([
                MaterialListTile(
                  leading: Icon(Icons.sports_mma),
                  title: Text(appLocalizations.identityKeyStrength),
                  subtitle: Text(
                    _parsedKey?.keyStrength != null
                        ? _parsedKey!.keyStrength.toString()
                        : appLocalizations.valueMissing,
                  ),
                  backgroundStyle: .lightened,
                ),
                MaterialListTile(
                  leading: Icon(Icons.numbers),
                  title: Text(appLocalizations.identityKeyVersion),
                  subtitle: Text(
                    _parsedKey?.version != null
                        ? _parsedKey!.version.toString()
                        : appLocalizations.valueMissing,
                  ),
                  backgroundStyle: .lightened,
                ),
              ]),
              ...MaterialListTile.group([
                MaterialListTile(
                  leading: Icon(Icons.vpn_key),
                  title: Text(appLocalizations.identityKeyId),
                  subtitle: Builder(
                    builder: (context) => Text(
                      _parsedKey?.keyID != null
                          ? _parsedKey!.keyID
                                .map((e) => e.toRadixString(16))
                                .join()
                                .toUpperCase()
                          : appLocalizations.valueMissing,
                      style: DefaultTextStyle.of(context).style.googleSansCode,
                    ),
                  ),
                  backgroundStyle: .lightened,
                ),
                MaterialListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text(appLocalizations.identityFingerprint),
                  subtitle: Builder(
                    builder: (context) => Text(
                      formatFingerprint(_keyData.fingerprint),
                      style: DefaultTextStyle.of(context).style.googleSansCode,
                    ),
                  ),
                  backgroundStyle: .lightened,
                ),
              ]),
              if (_passphraseIsStored != null)
                MaterialListTile(
                  leading: Icon(
                    _passphraseIsStored == true
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _passphraseIsStored != null
                        ? _passphraseIsStored!
                              ? Colors.lightBlueAccent.harmonizeWith(
                                  colorScheme.primary,
                                )
                              : null
                        : null,
                  ),
                  title: Text(
                    _passphraseIsStored == true
                        ? appLocalizations.identityPassphraseStored
                        : appLocalizations.identityPassphraseNotStored,
                  ),
                  backgroundStyle: .lightened,
                ),
              if (_onIdentityDeleted != null || _passphraseIsStored == true)
                ...MaterialListTile.group(
                  headline: MaterialListTileHeadline(
                    Text(appLocalizations.identityActionsHeadline),
                  ),
                  [
                    if (_onIdentityDeleted != null)
                      MaterialListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text(appLocalizations.identityDeleteKey),
                        backgroundStyle: .lightened,
                        onTap: () async {
                          Navigator.of(context).pop();
                          _onIdentityDeleted.call();
                        },
                      ),
                    if (_passphraseIsStored == true)
                      MaterialListTile(
                        leading: Icon(Icons.remove_red_eye_outlined),
                        title: Text(
                          appLocalizations.identityDeleteStoredPassphrase,
                        ),
                        backgroundStyle: .lightened,
                        onTap: () {
                          Navigator.of(context).pop();
                          _keyData.deleteKeyPassphrase();
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
              title: Text(
                user.name ?? appLocalizations.valueMissing,
                maxLines: 1,
                style: textTheme.headlineSmall!.bagelFatOne,
              ),
              subtitle: user.comment != null
                  ? Text(
                      appLocalizations.identityComment(user.comment!),
                      maxLines: 2,
                    )
                  : null,
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
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => _showDetailsDialog(context: context, textTheme: textTheme),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: colorScheme.outline)),
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
            Text(
              "${user.name ?? user.email}${user.comment != null ? " ${AppLocalizations.of(context).identityComment(user.comment!)}" : ""}",
              style: textTheme.labelLarge,
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

  const new({super.key, required this.user, this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Builder(
        builder: (context) => Text(
          user.email[0].toUpperCase(),
          style: DefaultTextStyle.of(context).style.googleSansCode,
        ),
      ),
    );
  }
}
