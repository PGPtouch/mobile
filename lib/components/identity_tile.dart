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

import '../database/key_store.dart';
import '../database/key_store.dart' as key_store;

class IdentityTile extends StatefulWidget {
  final key_store.Key keyData;
  final List<KeyUserId> userIds;
  final VoidCallback onTap;

  const new({super.key, required this.keyData, required this.userIds,required this.onTap});

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
    KeyStoreHandler.instance.addListener(onUpdate);
  }

  @override
  void dispose() {
    KeyStoreHandler.instance.removeListener(onUpdate);
    super.dispose();
  }

  void onUpdate() async {
    _passphraseIsStored = await KeyStoreHandler.instance.hasKeyPassphrase(
      widget.keyData.fingerprint,
    );
    if (mounted) setState(() {});
  }

  void _parseKey(Uint8List keyData) async {
    _parsedKey = await compute((_) => publicKeyFromBytes(keyData), null);
    _passphraseIsStored = await KeyStoreHandler.instance.hasKeyPassphrase(
      widget.keyData.fingerprint,
    );
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
    final size = MediaQuery.sizeOf(context);

    final users = widget.userIds.map((user) {
      return InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          clipBehavior: Clip.antiAlias,
          builder: (context) => Padding(
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
                      child: CircleAvatar(
                        child: Builder(
                          builder: (context) => Transform.translate(
                            offset: Offset(0, -2),
                            child: Text(
                              (user.name ?? user.email)[0],
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .bagelFatOne,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(user.name ?? "–", maxLines: 1),
                  subtitle: Text(
                    UserId(
                      name: user.name,
                      comment: user.comment,
                      email: user.email,
                    ).toString(),
                    maxLines: 2,
                  ),
                  backgroundStyle: .lightened,
                ),
                MaterialListTile(
                  leading: Icon(Icons.email),
                  title: Text(user.email, maxLines: 1),
                  backgroundStyle: .lightened,
                  onTap: () =>
                      launchUrl(Uri(scheme: "mailto", path: user.email)),
                  onLongPress: () =>
                      Clipboard.setData(ClipboardData(text: user.email)),
                ),
              ]),
            ),
          ),
        ),
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
                    child: CircleAvatar(
                      radius: 16,
                      child: Builder(
                        builder: (context) => Transform.translate(
                          offset: Offset(0, -2),
                          child: Text(
                            (user.name ?? user.email)[0],
                            style: DefaultTextStyle.of(context)
                                .style
                                .bagelFatOne,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(user.name ?? user.email, style: textTheme.labelLarge),
              SizedBox(width: 8),
            ],
          ),
        ),
      );
    });

    void showDetailScreen() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (context) => ConstrainedBox(
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
                    children: users.toList(),
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
                            : "–",
                      ),
                      backgroundStyle: .lightened,
                    ),
                    MaterialListTile(
                      leading: Icon(Icons.event_busy),
                      title: Text(appLocalizations.identityExpiration),
                      subtitle: Text(
                        _parsedKey != null
                            ? _parsedKey!.expirationTime != null
                                  ? DateFormat.yMMMd(
                                          appLocalizations.localeName,
                                        )
                                        .add_Hm()
                                        .format(_parsedKey!.expirationTime!)
                                  : appLocalizations.identityExpirationNever
                            : "–",
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
                          : "–",
                    ),
                    backgroundStyle: .lightened,
                  ),
                  MaterialListTile(
                    leading: Icon(Icons.numbers),
                    title: Text(appLocalizations.identityKeyVersion),
                    subtitle: Text(
                      _parsedKey?.version != null
                          ? _parsedKey!.version.toString()
                          : "–",
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
                            : "–",
                        style: DefaultTextStyle.of(context)
                            .style
                            .googleSansCode,
                      ),
                    ),
                    backgroundStyle: .lightened,
                  ),
                  MaterialListTile(
                    leading: Icon(Icons.fingerprint),
                    title: Text(appLocalizations.identityFingerprint),
                    subtitle: Builder(
                      builder: (context) => Text(
                        formatFingerprint(widget.keyData.fingerprint),
                        style: DefaultTextStyle.of(context)
                            .style
                            .googleSansCode,
                      ),
                    ),
                    backgroundStyle: .lightened,
                  ),
                ]),
                MaterialListTile(
                  leading: Icon(
                    Icons.security,
                    color: _passphraseIsStored != null
                        ? _passphraseIsStored!
                              ? Colors.lightGreen.harmonizeWith(
                                  colorScheme.primary,
                                )
                              : Colors.redAccent.harmonizeWith(
                                  colorScheme.primary,
                                )
                        : null,
                  ),
                  title: Text(
                    _passphraseIsStored != null
                        ? _passphraseIsStored!
                              ? appLocalizations.identityPassphraseStored
                              : appLocalizations.identityPassphraseNotStored
                        : appLocalizations.identityPassphraseLoading,
                  ),
                  backgroundStyle: .lightened,
                ),
                ...MaterialListTile.group(
                  headline: MaterialListTileHeadline(
                    Text(appLocalizations.identityActionsHeadline),
                  ),
                  [
                    MaterialListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text(appLocalizations.identityDeleteKey),
                      backgroundStyle: .lightened,
                      onTap: () async {
                        Navigator.of(context).pop();
                        final keyStore = KeyStoreHandler.instance.keyStore!;
                        await keyStore.transaction(() async {
                          await (keyStore.delete(
                            keyStore.keys,
                          )..where((c) => c.id.equals(widget.keyData.id))).go();
                          await (keyStore.delete(keyStore.keyUserIds)..where(
                                (c) => c.parent.equals(widget.keyData.id),
                              ))
                              .go();
                        });
                        await KeyStoreHandler.instance.deleteKeyPassphrase(
                          widget.keyData.fingerprint,
                        );
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
                          KeyStoreHandler.instance.deleteKeyPassphrase(
                            widget.keyData.fingerprint,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                formatFingerprint(widget.keyData.fingerprint)
                    .replaceFirst("\n", " "),
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                        : "–",
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
                        : "–",
                  ),
                  if (_parsedKey != null) ...[
                    TextSpan(text: " " * 4),
                    WidgetSpan(
                      child: Icon(
                        Icons.numbers,
                        size: textTheme.bodySmall?.fontSize,
                      ),
                      alignment: .middle,
                    ),
                    TextSpan(text: " "),
                    TextSpan(
                      text: _parsedKey?.version != null
                          ? _parsedKey!.version.toString()
                          : "–",
                    ),
                  ],
                ],
              ),
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      trailing: Icon(Icons.chevron_right),
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: _parsedKey != null ? () => showDetailScreen() : null,
    );
  }
}
